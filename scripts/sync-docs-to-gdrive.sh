#!/bin/bash
# Sync document files from ~/claude-projects/ to Google Drive for cross-device reading.
# Runs on a 5-minute interval via launchd.
# Only copies document files; skips .git, symlinks, build artifacts, etc.
set -euo pipefail

SRC="$HOME/claude-projects/"
DST="$HOME/Library/CloudStorage/GoogleDrive-tdore@ripple.com/My Drive/claude-projects-docs/"

# Create destination if needed
mkdir -p "$DST"

rsync -a --copy-links \
  --include='*/' \
  --include='*.pdf' \
  --include='*.tex' \
  --include='*.bib' \
  --include='*.md' \
  --include='*.txt' \
  --include='*.png' \
  --include='*.jpg' \
  --include='*.svg' \
  --exclude='*' \
  --exclude='.git/' \
  --prune-empty-dirs \
  "$SRC" "$DST"
