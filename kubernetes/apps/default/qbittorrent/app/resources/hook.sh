#!/bin/bash

# command line arguments:
# /scripts/hook.sh [added|finished] %N %L %G %F %R %D %C %Z %T

set -euo pipefail

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

CWA_BOOK_INGEST_PATH="/cwa-book-ingest"

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
      ebook_copier
      ;;
    *)
      log No special processing for category: "$TORRENT_CATEGORY"
      ;;
  esac
}

ebook_copier() {
  log Copying "$TORRENT_NAME" to CWA Auto Book Ingest Path

  _process_file() {
    if [[ "$1" == *.epub || "$1" == *.pdf || "$1" == *.mobi ]]; then
      cp "$1" "$CWA_BOOK_INGEST_PATH"
    else
      log No ebook file, skipping: "$1"
    fi
  }

  if [[ ! -d "$CWA_BOOK_INGEST_PATH" ]]; then
    log "Creating CWA Book Ingest Path: $CWA_BOOK_INGEST_PATH"
    mkdir -p "$CWA_BOOK_INGEST_PATH"
  fi

  if [[ -d "$TORRENT_CONTENT_PATH" ]]; then
    while read -r file; do
      _process_file "$file"
    done <<<"$(find "$TORRENT_CONTENT_PATH" -type f)"
  else
    _process_file "$TORRENT_CONTENT_PATH"
  fi
}

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log "######### Script started #########"
echo "TORRENT_STATUS      : $TORRENT_STATUS"
echo "TORRENT_NAME        : $TORRENT_NAME"
echo "TORRENT_CATEGORY    : $TORRENT_CATEGORY"
echo "TORRENT_TAGS        : $TORRENT_TAGS"
echo "TORRENT_CONTENT_PATH: $TORRENT_CONTENT_PATH"
echo "TORRENT_ROOT_PATH   : $TORRENT_ROOT_PATH"
echo "TORRENT_SAVE_PATH   : $TORRENT_SAVE_PATH"
echo "TORRENT_NUM_FILES   : $TORRENT_NUM_FILES"
echo "TORRENT_SIZE        : $TORRENT_SIZE"
echo "TORRENT_TRACKER     : $TORRENT_TRACKER"

main "$@"

log "######### Script finished #########"
