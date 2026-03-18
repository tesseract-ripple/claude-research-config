#!/bin/bash
# PostToolUse hook on Write|Edit: remind to check docs trigger table
# Only fires when the edited file is in a monitored path.
INPUT=$(cat)
f=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')
sid=$(echo "$INPUT" | jq -r '.session_id // empty')

# Only trigger for files in monitored paths
case "$f" in
  */.claude/*|*/claude-projects/docs/*|*/claude-projects/claude-research-config/*) ;;
  */.config/kitty/*|*/.config/tmux/*) ;;
  */.latexmkrc|*/.config/latexindent*) ;;
  */claude-usage/*) ;;
  *) exit 0 ;;  # not a monitored path, stay quiet
esac

# Edits to docs files themselves are the audit output — no reminder needed
case "$f" in
  */claude-projects/docs/*) exit 0 ;;
esac

# Determine which docs file is relevant
doc=""
case "$f" in
  */.claude/*|*/claude-research-config/*) doc="claude-setup.md" ;;
  */.config/kitty/*|*/.config/tmux/*|*/keybindings.json) doc="terminal-setup.md" ;;
  */.latexmkrc|*/.config/latexindent*) doc="latex-setup.md" ;;
  */claude-usage/*) doc="claude-usage-widget.md" ;;
esac

# Record this session as having edited a monitored file
[ -z "$sid" ] && exit 0
sentinel="$HOME/.claude/hooks/sentinels/docs-edited-this-session"
grep -qxF "$sid" "$sentinel" 2>/dev/null || echo "$sid" >> "$sentinel"

# Show reminder once per session (first qualifying edit only)
reminder_shown="$HOME/.claude/hooks/sentinels/docs-reminder-shown"
if grep -qxF "$sid" "$reminder_shown" 2>/dev/null; then
  exit 0
fi
echo "$sid" >> "$reminder_shown"

msg="DOCS CHECK: You edited '$f'. Update ~/claude-projects/docs/$doc if needed."
jq -n --arg msg "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$msg}}'
