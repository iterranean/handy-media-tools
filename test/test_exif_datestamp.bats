#!/usr/bin/env bats
#
# Tests for bin/exif-datestamp
#

load helpers/setup

BIN="${BATS_TEST_DIRNAME}/../bin"

# ---------------------------------------------------------------------------
# Argument validation
# ---------------------------------------------------------------------------

@test "exif-datestamp: exits 1 with no arguments" {
  run "${BIN}/exif-datestamp"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "exif-datestamp: exits 1 with empty argument" {
  run "${BIN}/exif-datestamp" ""
  [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# No EXIF
# ---------------------------------------------------------------------------

@test "exif-datestamp: exits 1 for file without EXIF date" {
  local no_exif="${FIXTURES}/no_exif.jpg"
  run "${BIN}/exif-datestamp" "$no_exif"
  [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Prints timestamp
# ---------------------------------------------------------------------------

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
