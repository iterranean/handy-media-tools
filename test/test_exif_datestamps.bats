#!/usr/bin/env bats
#
# Tests for bin/exif-datestamps
#

load helpers/setup

BIN="${BATS_TEST_DIRNAME}/../bin"

# ---------------------------------------------------------------------------
# Argument validation
# ---------------------------------------------------------------------------

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

@test "exif-datestamps: requires both directory and pattern" {
  run "${BIN}/exif-datestamps" "${FIXTURES}/mixed"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage:"* ]]
}

# ---------------------------------------------------------------------------
# Lists timestamps
# ---------------------------------------------------------------------------

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
