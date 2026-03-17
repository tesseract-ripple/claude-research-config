#!/bin/bash
# SessionStart hook: remind Claude to read memory files
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

msg="MEMORY READ REMINDER: Before doing substantive work, read the following memory files:\n- Global: $global_mem"
if [ -n "$project_mem" ]; then
  msg="$msg\n- Project: $project_mem"
fi
msg="$msg\nIf the user references prior work or says 'where were we', consult both files."

jq -n --arg msg "$msg" '{systemMessage:$msg}'
