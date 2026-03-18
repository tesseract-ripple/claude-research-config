#!/bin/bash
# Stop hook: remind Claude to update memory files before ending.
# Only fires if >30 min since last memory write (avoids noise on short sessions).
sentinel="$HOME/.claude/hooks/sentinels/last-memory-write"
threshold=1800
if [ -f "$sentinel" ]; then
  last_write=$(stat -f %m "$sentinel" 2>/dev/null || echo 0)
  now=$(date +%s)
  elapsed=$((now - last_write))
  if [ "$elapsed" -lt "$threshold" ]; then
    exit 0
  fi
fi

global_mem="$HOME/.claude/memory/MEMORY.md"
cwd_val=$(jq -r '.cwd // empty')
project_mem=""
check_dir="$cwd_val"
while [ -n "$check_dir" ] && [ "$check_dir" != "/" ]; do
  if [ -f "$check_dir/MEMORY.md" ]; then
    project_mem="$check_dir/MEMORY.md"
    break
  fi
  check_dir=$(dirname "$check_dir")
done

msg="MEMORY UPDATE REMINDER: Before ending, consider whether this session produced results worth recording.
- Global memory: $global_mem (preferences, cross-project notes)"
if [ -n "$project_mem" ]; then
  msg="$msg
- Project memory: $project_mem (research content, notation, decisions)"
fi
msg="$msg
Skip if trivial. Use targeted edits, max 2 per file."

jq -n --arg msg "$msg" '{systemMessage:$msg}'
