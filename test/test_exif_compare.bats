#!/usr/bin/env bats
#
# Tests for bin/exif-compare
#

load helpers/setup

BIN="${BATS_TEST_DIRNAME}/../bin"

# ---------------------------------------------------------------------------
# Argument validation
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Matching logic
# ---------------------------------------------------------------------------

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
