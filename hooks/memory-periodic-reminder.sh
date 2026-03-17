#!/bin/bash
# UserPromptSubmit hook: periodically remind to write memory
# Uses a sentinel file to avoid reminding on every message.
# Reminds if >30 minutes since last memory write (or if sentinel doesn't exist).
sentinel="$HOME/.claude/hooks/.last-memory-write"
threshold=1800  # 30 minutes in seconds

if [ -f "$sentinel" ]; then
  last_write=$(stat -f %m "$sentinel" 2>/dev/null || echo 0)
  now=$(date +%s)
  elapsed=$((now - last_write))
  if [ "$elapsed" -lt "$threshold" ]; then
    exit 0  # too soon, stay quiet
  fi
fi

# Find project memory by walking up from cwd
global_mem="$HOME/.claude/memory/MEMORY.md"
cwd_val=$(jq -r '.cwd // empty' 2>/dev/null)
project_mem=""
if [ -n "$cwd_val" ]; then
  check_dir="$cwd_val"
  while [ -n "$check_dir" ] && [ "$check_dir" != "/" ]; do
    if [ -f "$check_dir/MEMORY.md" ]; then
      project_mem="$check_dir/MEMORY.md"
      break
    fi
    check_dir=$(dirname "$check_dir")
  done
fi

msg="MEMORY WRITE CHECK (30+ min since last write): If this session has produced any results, decisions, or milestones worth recording, update memory now — don't wait for session end. Other concurrent sessions benefit from early writes.
- Global: $global_mem"
if [ -n "$project_mem" ]; then
  msg="$msg
- Project: $project_mem"
fi
msg="$msg
After writing, run: touch ~/.claude/hooks/.last-memory-write (to reset the timer).
If nothing worth recording has happened, ignore this reminder."

# Reset the timer so we don't fire again for another 30 minutes
touch "$sentinel"

jq -n --arg msg "$msg" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$msg}}'
