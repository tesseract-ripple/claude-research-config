#!/bin/bash
# Sync document files from ~/claude-projects/ to Google Drive via rclone.
# Runs on a 1-hour interval via launchd.
# Uses rclone (Google Drive API) to bypass macOS TCC restrictions on
# background access to File Provider paths.
set -euo pipefail

LOCKFILE="/tmp/claude-docs-gdrive-sync.lock"
BACKOFF_FILE="/tmp/claude-docs-gdrive-sync.backoff"
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
    # Success — clear backoff state
    rm -f "$BACKOFF_FILE"
else
    # Failure — increment backoff counter
    failures=0
    [[ -f "$BACKOFF_FILE" ]] && failures=$(cat "$BACKOFF_FILE")
    echo $(( failures + 1 )) > "$BACKOFF_FILE"
    echo "$(date): rclone failed (failure #$(( failures + 1 )))" >> "$LOG"
fi
