#!/usr/bin/env bash
#
# helpers/setup.bash — sourced by bats to create test fixtures.
#
# FIXTURES is set to the absolute path of test/fixtures/.
# Each fixture is a real file with EXIF metadata added via exiftool.

setup_file() {
  FIXTURES="${BATS_TEST_DIRNAME}/fixtures"
  export FIXTURES

  # Clean and recreate fixtures directory
  rm -rf "$FIXTURES"
  mkdir -p "$FIXTURES"/{mixed,subdir_a,subdir_b}

  # --- Helper: create a minimal JPEG using Pillow, then add EXIF via exiftool ---
  _MAKE_IMAGE="${BATS_TEST_DIRNAME}/helpers/make_image.py"
  _make_image() {
    python3 "$_MAKE_IMAGE" "$1"
  }

  # --- Fixture 1: file with DateTimeOriginal ---
  _make_image "${FIXTURES}/with_datestamp.jpg"
  exiftool -overwrite_original \
    -DateTimeOriginal="2024:06:15 14:30:00" \
    "${FIXTURES}/with_datestamp.jpg" >/dev/null

  # --- Fixture 2: file with CreateDate only (no DateTimeOriginal) ---
  _make_image "${FIXTURES}/create_only.jpg"
  exiftool -overwrite_original \
    -CreateDate="2024:06:15 14:30:00" \
    "${FIXTURES}/create_only.jpg" >/dev/null

  # --- Fixture 3: file with NO EXIF date ---
  _make_image "${FIXTURES}/no_exif.jpg"
  # (no exiftool call — intentionally no EXIF date)

  # --- Fixture 4: PNG without EXIF date ---
  _make_image "${FIXTURES}/no_exif.png"
  # Rename to .png — exiftool still works on the binary content

  # --- Fixture 5: file with different EXIF timestamp (for matching tests) ---
  _make_image "${FIXTURES}/mixed/other_photo.jpg"
  exiftool -overwrite_original \
    -DateTimeOriginal="2023:01:10 08:15:30" \
    "${FIXTURES}/mixed/other_photo.jpg" >/dev/null

  # --- Fixture 6: copy of with_datestamp into mixed/ (same EXIF as with_datestamp.jpg) ---
  cp "${FIXTURES}/with_datestamp.jpg" "${FIXTURES}/mixed/photo.jpg"

  # --- Fixture 7: a file in subdirs (same content, different paths) ---
  cp "${FIXTURES}/with_datestamp.jpg" "${FIXTURES}/subdir_a/photo.jpg"
  cp "${FIXTURES}/with_datestamp.jpg" "${FIXTURES}/subdir_b/photo.jpg"

  # --- Fixture 8: file in mixed/ without EXIF ---
  cp "${FIXTURES}/no_exif.jpg" "${FIXTURES}/mixed/no_exif.jpg"

  # --- Fixture 9: PNG with EXIF in mixed/ (for glob pattern test) ---
  _make_image "${FIXTURES}/mixed/snapshot.png"
  exiftool -overwrite_original \
    -DateTimeOriginal="2024:06:15 14:30:00" \
    "${FIXTURES}/mixed/snapshot.png" >/dev/null
}
