#!/bin/bash
# Stop hook: block if .tex files have uncommitted changes without diff PDFs
tex_files=$(git diff --name-only HEAD 2>/dev/null | grep '\.tex$' || true)
if [ -n "$tex_files" ]; then
  jq -n --arg files "$tex_files" '{decision:"block",reason:("LATEXDIFF REMINDER: The following .tex files have uncommitted changes and need diff PDFs generated before you stop:\n" + $files + "\nSee ~/.claude/CLAUDE.md Diff PDF generation for the workflow. If diffs were already generated or the changes are trivial (e.g. .gitignore-only session), you may proceed.")}'
fi
