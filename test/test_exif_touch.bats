#!/usr/bin/env bats
#
# Tests for bin/exif-touch
#

load helpers/setup

BIN="${BATS_TEST_DIRNAME}/../bin"

# ---------------------------------------------------------------------------
# Argument validation
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Generates touch commands
# ---------------------------------------------------------------------------

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
