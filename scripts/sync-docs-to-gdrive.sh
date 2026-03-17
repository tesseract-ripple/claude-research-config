#!/bin/bash
# Sync document files from ~/claude-projects/ to Google Drive via rclone.
# Runs on a 5-minute interval via launchd.
# Uses rclone (Google Drive API) to bypass macOS TCC restrictions on
# background access to File Provider paths.
set -euo pipefail

SRC="$HOME/claude-projects/"
DST="gdrive:claude-projects-docs/"

rclone sync "$SRC" "$DST" \
  --copy-links \
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
  >> /tmp/claude-docs-gdrive-sync.log 2>&1
