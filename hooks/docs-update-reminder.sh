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

# Determine which docs file is relevant
doc=""
case "$f" in
  */.claude/*|*/claude-research-config/*) doc="claude-setup.md" ;;
  */.config/kitty/*|*/.config/tmux/*|*/keybindings.json) doc="terminal-setup.md" ;;
  */.latexmkrc|*/.config/latexindent*) doc="latex-setup.md" ;;
  */claude-usage/*) doc="claude-usage-widget.md" ;;
esac

msg="DOCS CHECK: You edited '$f'. Update ~/claude-projects/docs/$doc if needed."

# Mark that config/docs were touched this session (gates semantic check at Stop)
touch "$HOME/.claude/hooks/.docs-edited-this-session"

jq -n --arg msg "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$msg}}'
