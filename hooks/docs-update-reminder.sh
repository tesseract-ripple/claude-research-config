#!/bin/bash
# PostToolUse hook on Write|Edit: remind to check docs trigger table
# Only fires when the edited file is in a monitored path.
f=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty')

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

sentinel="$HOME/.claude/hooks/sentinels/docs-edited-this-session"
audit_done="$HOME/.claude/hooks/sentinels/docs-audit-done"

# Always set the sentinel (gates the Stop audit), UNLESS audit already ran —
# in that case, still show the reminder but don't re-arm the Stop hook
if [ ! -f "$audit_done" ]; then
  touch "$sentinel"
fi

# Show reminder once per session (first qualifying edit only)
# Use a separate flag so reminder logic is independent of audit state
reminder_shown="$HOME/.claude/hooks/sentinels/docs-reminder-shown"
if [ -f "$reminder_shown" ]; then
  exit 0
fi
touch "$reminder_shown"

msg="DOCS CHECK: You edited '$f'. Update ~/claude-projects/docs/$doc if needed."
jq -n --arg msg "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$msg}}'
