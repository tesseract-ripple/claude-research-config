#!/bin/bash
# PreToolUse hook on Edit: remind to capture latexdiff baseline before first .tex edit
f=$(jq -r '.tool_input.file_path // empty')
case "$f" in
  *.tex)
    base=$(basename "$f" .tex)
    if [ ! -f "/tmp/${base}-baseline.tex" ]; then
      msg="LATEXDIFF BASELINE: You are about to edit '$f' for the first time this session. Before proceeding, capture the baseline:\n  git show HEAD:$(basename "$f") > /tmp/${base}-baseline.tex\nIf the file is new (not yet committed), skip this step."
      jq -n --arg msg "$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$msg}}'
    fi
    ;;
esac
