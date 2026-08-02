# Handy Media Tools

Small collection of handy shell scripts complimenting exiftool on Mac and Linux.

## Pre-requisites

- bash
- exiftool

```sh
apt-get install exiftool
brew install exiftool
```

## Development tools

Install system tools and set up pre-commit hooks:

```sh
brew bundle
pip install pre-commit && pre-commit install
```

For a signed release artifact (from a `v*` tag push to GitHub):

```sh
gh attestation verify handy-media-tools-vX.Y.Z.tar.gz --owner <owner>
```

## Use

- Compare two directories, finding matching/renamed/moved files:

  ```sh
  ./bin/exif-compare 'DIR_LEFT' 'DIR_RIGHT'
  ./bin/exif-compare 'DIR_LEFT' 'DIR_RIGHT' --assure        # also compare SHA checksums
  ./bin/exif-compare 'DIR_LEFT' 'DIR_RIGHT' --summary-only  # just the summary line
  ```

  Matches by a hierarchy of cost:

  1. Exact relative path (cheapest)
  1. Filename + size (same name, possibly different subdir)
  1. Filename + EXIF datestamp (same name & capture time)
  1. SHA-256 checksum (expensive — only with `--assure`)

  Unmatched files are shown first; matched/duplicate pairs at the end.

- Extract a single file's EXIF timestamp:

  ```sh
  ./bin/exif-datestamp photo.jpg
  ```

- List EXIF timestamps for all matching files in a directory:

  ```sh
  ./bin/exif-datestamps . '*.jpg'
  ```

- Generate `mv` commands to rename files with a `YYYYMMDD-HHMMSS` prefix from EXIF data:

  ```sh
  ./bin/exif-rename . '*.jpg' > rename.sh && bash rename.sh
  ```

- Generate `touch` commands to set file mtime/atime from EXIF creation date:

  ```sh
  ./bin/exif-touch . '*.jpg' > touch.sh && bash touch.sh
  ```
