#!/bin/bash

# command line arguments:
# /scripts/hook.sh [added|finished] %N %L %G %F %R %D %C %Z %T

set -xeuo pipefail

LOG_FILE="/tmp/qbittorrent_hook.log"
exec &>>"$LOG_FILE"

TORRENT_STATUS=$1       # Torrent status (added, or finished)
TORRENT_NAME=$2         # %N - Torrent name
TORRENT_CATEGORY=$3     # %L - Category
TORRENT_TAGS=$4         # %G - Tags (separated by comma)
TORRENT_CONTENT_PATH=$5 # %F - Content path (same as root path for multifile torrent)
TORRENT_ROOT_PATH=$6    # %R - Root path (first torrent subdirectory path)
TORRENT_SAVE_PATH=$7    # %D - Save path
TORRENT_NUM_FILES=$8    # %C - Number of files
TORRENT_SIZE=$9         # %Z - Torrent size (bytes)
TORRENT_TRACKER=${10}   # %T - Current tracker

CWA_BOOK_INGEST_PATH="/media/downloads/temp/cwa-book-ingest"

main() {
  log Script arguments: "$@"

  case "$TORRENT_STATUS" in
    added) added ;;
    finished) finished ;;
    *)
      log Unknown torrent status: "$TORRENT_STATUS"
      ;;
  esac
}

added() {
  log Torrent added: "$TORRENT_NAME"
}

finished() {
  log Torrent finished: "$TORRENT_NAME"
  case "$TORRENT_CATEGORY" in
    ebooks)
      log Processing ebooks category for torrent: "$TORRENT_NAME"
      ;;
    *)
      log No special processing for category: "$TORRENT_CATEGORY"
      ;;
  esac
}

ebook_copier() {
  log Copying "$TORRENT_NAME" to CWA Auto Book Ingest Path
  # if [[ -d "$TORRENT_CONTENT_PATH" ]];
}

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $*"
}

main "$@"

# # Checking if the second argument is not 'no-copy'
# if [[ $2 != 'no-copy' ]]; then
#   # Checking if the provided path is a directory
#   if [ -d "$1" ]; then
#     new_path="${1/\/Seeding/\/data}"
#     new_path="${new_path%/*}"
#     mkdir -p "$new_path"
#     if [ -e "$new_path/$(basename "$1")" ]; then
#       echo "Error: Folder '$(basename "$1")' already exists in destination." >> "$error_file"
#     else
#       # Use rsync to copy directory excluding image files
#       rsync -av --exclude='*.jpg' --exclude='*.jpeg' --exclude='*.png' --exclude='*.gif' "$1/" "$new_path/$(basename "$1")/"
#       # Remove empty directories
#       find "$new_path/$(basename "$1")" -type d -empty -delete
#       chown -R 99:100 "$new_path/$(basename "$1")"
#     fi
#   else
#     # If the provided path is a file, handle it accordingly
#     new_file_path="${1/\/Seeding/\/data}"
#     new_file_path="${new_file_path%/*}"
#     mkdir -p "$new_file_path"
#     if [ -e "$new_file_path/$(basename "$1")" ]; then
#       echo "Error: File '$(basename "$1")' already exists in destination." >> "$error_file"
#     else
#       # Use rsync to copy the file
#       rsync -av "$1" "$new_file_path/"
#       chown 99:100 "$new_file_path/$(basename "$1")"
#     fi
#   fi
# fi
#
