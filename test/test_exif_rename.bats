#!/usr/bin/env bats
#
# Tests for bin/exif-rename
#

load helpers/setup

BIN="${BATS_TEST_DIRNAME}/../bin"

# ---------------------------------------------------------------------------
# Argument validation
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Generates mv commands
# ---------------------------------------------------------------------------

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
  touch_count=$(echo "$output" | grep -c "^touch")
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
