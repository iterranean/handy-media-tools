#!/usr/bin/env bats
#
# Tests for all exif-* tools in bin/
#
# Setup creates test images with EXIF metadata using exiftool.
# Each tool under test is called with the BIN path set to this repo's bin/.

load helpers/setup

# ---------------------------------------------------------------------------
# Bin path
# ---------------------------------------------------------------------------

BIN="${BATS_TEST_DIRNAME}/../bin"

# ===========================================================================
# exif-datestamp
# ===========================================================================

@test "exif-datestamp: exits 1 with no arguments" {
  run "${BIN}/exif-datestamp"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "exif-datestamp: exits 1 with empty argument" {
  run "${BIN}/exif-datestamp" ""
  [ "$status" -ne 0 ]
}

@test "exif-datestamp: exits 1 for file without EXIF date" {
  local no_exif="${FIXTURES}/no_exif.jpg"
  run "${BIN}/exif-datestamp" "$no_exif"
  [ "$status" -ne 0 ]
}

@test "exif-datestamp: prints DateTimeOriginal when present" {
  local with_exif="${FIXTURES}/with_datestamp.jpg"
  run "${BIN}/exif-datestamp" "$with_exif"
  [ "$status" -eq 0 ]
  [ "${#lines[0]}" -eq 15 ]   # YYYYMMDD-HHMMSS = 15 chars
  [[ "$output" =~ ^[0-9]{8}-[0-9]{6}$ ]]
}

@test "exif-datestamp: prints CreateDate fallback when DateTimeOriginal absent" {
  local create_only="${FIXTURES}/create_only.jpg"
  run "${BIN}/exif-datestamp" "$create_only"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]{8}-[0-9]{6}$ ]]
}

@test "exif-datestamp: output matches the EXIF timestamp we set" {
  local with_exif="${FIXTURES}/with_datestamp.jpg"
  # The setup script sets DateTimeOriginal to "2024:06:15 14:30:00"
  # exiftool -d "%Y%m%d-%H%M%S" should produce "20240615-143000"
  run "${BIN}/exif-datestamp" "$with_exif"
  [ "$status" -eq 0 ]
  [ "$output" = "20240615-143000" ]
}

# ===========================================================================
# exif-datestamps
# ===========================================================================

@test "exif-datestamps: exits 1 with no arguments" {
  run "${BIN}/exif-datestamps"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "exif-datestamps: exits 1 with empty pattern" {
  run "${BIN}/exif-datestamps" ""
  [ "$status" -ne 0 ]
}

@test "exif-datestamps: exits 1 with only directory, no pattern" {
  run "${BIN}/exif-datestamps" "/tmp" ""
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "exif-datestamps: lists timestamps for matching files" {
  local dir="${FIXTURES}/mixed"
  run "${BIN}/exif-datestamps" "$dir" "*.jpg"
  [ "$status" -eq 0 ]
  # Should have 2 lines (two files with EXIF)
  [ "${#lines[@]}" -eq 2 ]
  # Each line should contain a timestamp and a filename
  for line in "${lines[@]}"; do
    [[ "$line" == *": "* ]]
  done
}

@test "exif-datestamps: skips files without EXIF" {
  local dir="${FIXTURES}/mixed"
  run "${BIN}/exif-datestamps" "$dir" "*.jpg"
  [ "$status" -eq 0 ]
  # Should NOT contain the no_exif file
  [[ "$output" != *"no_exif"* ]]
}

@test "exif-datestamps: respects glob pattern" {
  local dir="${FIXTURES}/mixed"
  run "${BIN}/exif-datestamps" "$dir" "*.png"
  [ "$status" -eq 0 ]
  # Only one PNG with EXIF
  [ "${#lines[@]}" -eq 1 ]
}

@test "exif-datestamps: empty directory produces no output" {
  local empty="${BATS_TMPDIR}/empty_dir"
  mkdir -p "$empty"
  run "${BIN}/exif-datestamps" "$empty" "*"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exif-datestamps: requires both directory and pattern" {
  run "${BIN}/exif-datestamps" "${FIXTURES}/mixed"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage:"* ]]
}

# ===========================================================================
# exif-rename
# ===========================================================================

@test "exif-rename: exits 1 with no arguments" {
  run "${BIN}/exif-rename"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "exif-rename: exits 1 with empty pattern" {
  run "${BIN}/exif-rename" ""
  [ "$status" -ne 0 ]
}

@test "exif-rename: exits 1 with only directory, no pattern" {
  run "${BIN}/exif-rename" "${FIXTURES}/mixed" ""
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "exif-rename: generates mv commands for files with EXIF" {
  local dir="${FIXTURES}/mixed"
  run "${BIN}/exif-rename" "$dir" "*.jpg"
  [ "$status" -eq 0 ]
  # Should produce 2 touch commands (two JPGs with EXIF)
  local touch_count
  touch_count=$(echo "$output" | grep -c "^touch")
  [ "$touch_count" -eq 2 ]
}

@test "exif-rename: skips files without EXIF" {
  local dir="${FIXTURES}/mixed"
  run "${BIN}/exif-rename" "$dir" "*.jpg"
  [[ "$output" != *"no_exif"* ]]
}

@test "exif-rename: skips already datestamped files" {
  local dir="${BATS_TMPDIR}/already_datestamped"
  mkdir -p "$dir"
  cp "${FIXTURES}/with_datestamp.jpg" "$dir/20240615-143000-photo.jpg"
  run "${BIN}/exif-rename" "$dir" "*.jpg"
  [ "$status" -eq 0 ]
  # Should produce 0 commands (file already has datestamp prefix)
  local touch_count
  # shellcheck disable=SC2126
  touch_count=$(echo "$output" | grep "^touch" | wc -l)
  touch_count=${touch_count// /}
  [ "$touch_count" -eq 0 ]
}

@test "exif-rename: output contains correct touch timestamp format" {
  local dir="${FIXTURES}/mixed"
  run "${BIN}/exif-rename" "$dir" "*.jpg"
  [ "$status" -eq 0 ]
  # Extract timestamps and verify all match the expected format
  local timestamps
  timestamps=$(echo "$output" | sed -n "s/.*-t '\([^']*\)'.*/\1/p")
  [ "${#timestamps}" -gt 0 ]
  # Any non-matching line would cause grep -v to output it
  local non_matching
  non_matching=$(echo "$timestamps" | grep -vE '^[0-9]{12}\.[0-9]{2}$' || true)
  [ -z "$non_matching" ]
}

@test "exif-rename: empty directory produces no output" {
  local empty="${BATS_TMPDIR}/empty_rename"
  mkdir -p "$empty"
  run "${BIN}/exif-rename" "$empty" "*"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ===========================================================================
# exif-touch
# ===========================================================================

@test "exif-touch: exits 1 with no arguments" {
  run "${BIN}/exif-touch"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "exif-touch: exits 1 with empty pattern" {
  run "${BIN}/exif-touch" ""
  [ "$status" -ne 0 ]
}

@test "exif-touch: exits 1 with only directory, no pattern" {
  run "${BIN}/exif-touch" "${FIXTURES}/mixed" ""
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "exif-touch: generates touch commands for files with EXIF" {
  local dir="${FIXTURES}/mixed"
  run "${BIN}/exif-touch" "$dir" "*.jpg"
  [ "$status" -eq 0 ]
  # Should produce 2 touch commands
  local touch_count
  touch_count=$(echo "$output" | grep -c "^touch")
  [ "$touch_count" -eq 2 ]
}

@test "exif-touch: skips files without EXIF" {
  local dir="${FIXTURES}/mixed"
  run "${BIN}/exif-touch" "$dir" "*.jpg"
  [[ "$output" != *"no_exif"* ]]
}

@test "exif-touch: touch command has correct timestamp format" {
  local dir="${FIXTURES}/mixed"
  run "${BIN}/exif-touch" "$dir" "*.jpg"
  [ "$status" -eq 0 ]
  local timestamps
  timestamps=$(echo "$output" | sed -n "s/.*-t '\([^']*\)'.*/\1/p")
  [ "${#timestamps}" -gt 0 ]
  local non_matching
  non_matching=$(echo "$timestamps" | grep -vE '^[0-9]{12}\.[0-9]{2}$' || true)
  [ -z "$non_matching" ]
}

@test "exif-touch: empty directory produces no output" {
  local empty="${BATS_TMPDIR}/empty_touch"
  mkdir -p "$empty"
  run "${BIN}/exif-touch" "$empty" "*"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ===========================================================================
# exif-compare
# ===========================================================================

@test "exif-compare: exits 1 with no arguments" {
  run "${BIN}/exif-compare"
  [ "$status" -ne 0 ]
  [[ "$output" == *"ERROR:"* ]]
}

@test "exif-compare: exits 1 with only one argument" {
  run "${BIN}/exif-compare" "/tmp"
  [ "$status" -ne 0 ]
  [[ "$output" == *"ERROR:"* ]]
}

@test "exif-compare: exits 1 for non-existent left directory" {
  run "${BIN}/exif-compare" "/nonexistent/left" "/tmp"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not a directory"* ]]
}

@test "exif-compare: exits 1 for non-existent right directory" {
  run "${BIN}/exif-compare" "/tmp" "/nonexistent/right"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not a directory"* ]]
}

@test "exif-compare: shows help with -h" {
  run "${BIN}/exif-compare" -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "exif-compare: shows help with --help" {
  run "${BIN}/exif-compare" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "exif-compare: two identical empty directories" {
  local left="${BATS_TMPDIR}/compare_empty_left"
  local right="${BATS_TMPDIR}/compare_empty_right"
  mkdir -p "$left" "$right"
  run "${BIN}/exif-compare" "$left" "$right"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Summary: 0 matched, 0 missing on right, 0 missing on left"* ]]
}

@test "exif-compare: files only in left directory" {
  local left="${BATS_TMPDIR}/compare_left_only"
  local right="${BATS_TMPDIR}/compare_right_empty"
  mkdir -p "$left" "$right"
  cp "${FIXTURES}/with_datestamp.jpg" "$left/photo.jpg"
  run "${BIN}/exif-compare" "$left" "$right"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Left only"* ]]
  # No "Right only" section when right is empty
  [[ "$output" != *"Right only"* ]]
  [[ "$output" == *"1 missing on right"* ]]
  [[ "$output" == *"0 missing on left"* ]]
}

@test "exif-compare: files only in right directory" {
  local left="${BATS_TMPDIR}/compare_left_empty"
  local right="${BATS_TMPDIR}/compare_right_only"
  mkdir -p "$left" "$right"
  cp "${FIXTURES}/with_datestamp.jpg" "$right/photo.jpg"
  run "${BIN}/exif-compare" "$left" "$right"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Left only"* ]]
  [[ "$output" == *"Right only"* ]]
}

@test "exif-compare: identical files in same path match by cost=path" {
  local left="${BATS_TMPDIR}/compare_same_path"
  local right="${BATS_TMPDIR}/compare_same_path"
  mkdir -p "$left" "$right"
  cp "${FIXTURES}/with_datestamp.jpg" "$left/photo.jpg"
  cp "${FIXTURES}/with_datestamp.jpg" "$right/photo.jpg"
  run "${BIN}/exif-compare" "$left" "$right"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Matched"* ]]
  [[ "$output" == *"1 matched"* ]]
  [[ "$output" == *"path"* ]]
}

@test "exif-compare: same file in different subdirs matches by cost=size" {
  local left="${BATS_TMPDIR}/compare_size_left"
  local right="${BATS_TMPDIR}/compare_size_right"
  mkdir -p "$left/sub" "$right/other"
  cp "${FIXTURES}/with_datestamp.jpg" "$left/sub/photo.jpg"
  cp "${FIXTURES}/with_datestamp.jpg" "$right/other/photo.jpg"
  run "${BIN}/exif-compare" "$left" "$right"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Matched"* ]]
  [[ "$output" == *"size"* ]]
}

@test "exif-compare: --summary-only hides detailed output" {
  local left="${BATS_TMPDIR}/compare_summary_left"
  local right="${BATS_TMPDIR}/compare_summary_right"
  mkdir -p "$left" "$right"
  cp "${FIXTURES}/with_datestamp.jpg" "$left/photo.jpg"
  cp "${FIXTURES}/create_only.jpg" "$right/photo.jpg"
  run "${BIN}/exif-compare" "$left" "$right" --summary-only
  [ "$status" -eq 0 ]
  [[ "$output" == *"Summary:"* ]]
  # Should NOT contain detailed sections
  [[ "$output" != *"Left only"* ]]
  [[ "$output" != *"Matched"* ]]
}

@test "exif-compare: --assure flag is accepted" {
  local left="${BATS_TMPDIR}/compare_assure_left"
  local right="${BATS_TMPDIR}/compare_assure_right"
  mkdir -p "$left" "$right"
  cp "${FIXTURES}/with_datestamp.jpg" "$left/photo.jpg"
  cp "${FIXTURES}/with_datestamp.jpg" "$right/photo.jpg"
  run "${BIN}/exif-compare" "$left" "$right" --assure
  [ "$status" -eq 0 ]
  [[ "$output" == *"Summary:"* ]]
}

@test "exif-compare: unmatched files listed before matched" {
  local left="${BATS_TMPDIR}/compare_order_left"
  local right="${BATS_TMPDIR}/compare_order_right"
  mkdir -p "$left" "$right"
  cp "${FIXTURES}/with_datestamp.jpg" "$left/only_left.jpg"
  cp "${FIXTURES}/create_only.jpg" "$right/only_right.jpg"
  run "${BIN}/exif-compare" "$left" "$right"
  [ "$status" -eq 0 ]
  # "Left only" should appear before "Right only" in output
  local left_pos right_pos
  left_pos=$(echo "$output" | grep -n "Left only" | head -1 | cut -d: -f1)
  right_pos=$(echo "$output" | grep -n "Right only" | head -1 | cut -d: -f1)
  [ "$left_pos" -lt "$right_pos" ]
}

@test "exif-compare: skips ._ (macOS resource fork) files" {
  local left="${BATS_TMPDIR}/compare_dotleft"
  local right="${BATS_TMPDIR}/compare_dotright"
  mkdir -p "$left" "$right"
  cp "${FIXTURES}/with_datestamp.jpg" "$left/photo.jpg"
  touch "$left/._photo.jpg"
  touch "$right/._photo.jpg"
  run "${BIN}/exif-compare" "$left" "$right"
  [ "$status" -eq 0 ]
  [[ "$output" != *"._"* ]]
}
