#!/bin/bash
# Stop hook: block if .tex files have uncommitted changes without diff PDFs.
# Only blocks once per session to prevent infinite loops.
sentinel="$HOME/.claude/hooks/.latexdiff-stop-checked"

if [ -f "$sentinel" ]; then
  exit 0
fi

tex_files=$(git diff --name-only HEAD 2>/dev/null | grep '\.tex$' || true)
if [ -n "$tex_files" ]; then
  # Remove sentinel BEFORE blocking so next Stop is not blocked again
  touch "$sentinel"
  jq -n --arg files "$tex_files" '{decision:"block",reason:("LATEXDIFF REMINDER: The following .tex files have uncommitted changes and need diff PDFs generated before you stop:\n" + $files + "\nSee ~/.claude/CLAUDE.md Diff PDF generation for the workflow. If diffs were already generated or the changes are trivial (e.g. .gitignore-only session), you may proceed.")}'
fi
