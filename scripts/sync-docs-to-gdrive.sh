#!/bin/bash
# Sync document files from ~/claude-projects/ to Google Drive via rclone.
# Runs on a 10-minute interval via launchd, but only calls rclone when
# local files have actually changed (cheap local check first).
# Uses rclone (Google Drive API) to bypass macOS TCC restrictions on
# background access to File Provider paths.
set -euo pipefail

LOCKFILE="/tmp/claude-docs-gdrive-sync.lock"
BACKOFF_FILE="/tmp/claude-docs-gdrive-sync.backoff"
STAMP_FILE="/tmp/claude-docs-gdrive-sync.stamp"
LOG="/tmp/claude-docs-gdrive-sync.log"

# Prevent overlapping runs
if ! mkdir "$LOCKFILE" 2>/dev/null; then
    echo "$(date): sync already running, skipping" >> "$LOG"
    exit 0
fi
trap 'rmdir "$LOCKFILE" 2>/dev/null' EXIT

# Exponential backoff on repeated failures
if [[ -f "$BACKOFF_FILE" ]]; then
    failures=$(cat "$BACKOFF_FILE")
    backoff_until=$(stat -f %m "$BACKOFF_FILE" 2>/dev/null || echo 0)
    wait_secs=$(( (2 ** failures) * 60 ))
    resume_at=$(( backoff_until + wait_secs ))
    now=$(date +%s)
    if (( now < resume_at )); then
        echo "$(date): backing off (${failures} failures, next try in $(( resume_at - now ))s)" >> "$LOG"
        exit 0
    fi
fi

SRC="$HOME/claude-projects/"

# Cheap local check: have any syncable files changed since last successful sync?
FIND_ARGS=( "$SRC" -L
    \( -name .git -o -name rippled -o -name build -o -name node_modules -o -name 'zotero' \) -prune
    -o \( -name '*.pdf' -o -name '*.tex' -o -name '*.bib' -o -name '*.md'
          -o -name '*.txt' -o -name '*.png' -o -name '*.jpg' -o -name '*.svg' \)
    ! -name '*-diff.pdf' ! -name '*-diff.tex'
    -type f -print )

if [[ -f "$STAMP_FILE" ]]; then
    # Check if any matching file is newer than the stamp
    changed=$(find "${FIND_ARGS[@]}" -newer "$STAMP_FILE" 2>/dev/null | head -1)
    if [[ -z "$changed" ]]; then
        exit 0
    fi
fi

DST="gdrive:claude-projects-docs/"

if rclone sync "$SRC" "$DST" \
  -L \
  --filter='- .git/**' \
  --filter='- rippled/**' \
  --filter='- zotero/storage/**' \
  --filter='- **/build/**' \
  --filter='- **/node_modules/**' \
  --filter='- *-diff.pdf' \
  --filter='- *-diff.tex' \
  --filter='+ *.pdf' \
  --filter='+ *.tex' \
  --filter='+ *.bib' \
  --filter='+ *.md' \
  --filter='+ *.txt' \
  --filter='+ *.png' \
  --filter='+ *.jpg' \
  --filter='+ *.svg' \
  --filter='- *' \
  >> "$LOG" 2>&1; then
    rm -f "$BACKOFF_FILE"
    touch "$STAMP_FILE"
else
    failures=0
    [[ -f "$BACKOFF_FILE" ]] && failures=$(cat "$BACKOFF_FILE")
    echo $(( failures + 1 )) > "$BACKOFF_FILE"
    echo "$(date): rclone failed (failure #$(( failures + 1 )))" >> "$LOG"
fi
