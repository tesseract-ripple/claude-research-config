#!/bin/bash
# PostToolUse hook on Bash: remind about docs when commands create/modify
# files in monitored directories. Silent for all other Bash commands.
INPUT=$(cat)
cmd=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
sid=$(echo "$INPUT" | jq -r '.session_id // empty')

# Only trigger on commands that create, copy, move, or clone into monitored paths
case "$cmd" in
  *mkdir*|*cp\ *|*mv\ *|*git\ clone*|*git\ init*|*touch\ *)
    ;;
  *)
    exit 0  # not a structural command, stay quiet
    ;;
esac

# Check if any monitored path appears in the command
monitored="\.claude/|claude-projects/|\.config/kitty|\.config/tmux"
if ! echo "$cmd" | grep -qE "$monitored"; then
  exit 0  # structural command but not in a monitored path
fi

# Commands targeting docs/ itself are the audit output — no reminder needed
# Touching sentinel dotfiles in hooks/ is not a structural change
case "$cmd" in
  *claude-projects/docs/*) exit 0 ;;
  */.claude/hooks/sentinels/*) exit 0 ;;
esac

# Record this session as having edited a monitored file
[ -z "$sid" ] && exit 0
sentinel="$HOME/.claude/hooks/sentinels/docs-edited-this-session"
grep -qxF "$sid" "$sentinel" 2>/dev/null || echo "$sid" >> "$sentinel"

# Show reminder once per session (first qualifying command only)
reminder_shown="$HOME/.claude/hooks/sentinels/docs-reminder-shown"
if grep -qxF "$sid" "$reminder_shown" 2>/dev/null; then
  exit 0
fi
echo "$sid" >> "$reminder_shown"

msg="DOCS CHECK (Bash): You just ran a structural command in a monitored path:
  $cmd
This may require updating docs in ~/claude-projects/docs/:
| Docs file | Update when editing... |
|---|---|
| claude-setup.md | ~/.claude/ structure, settings.json, agents, skills, MCP servers, ~/claude-projects/ tree |
| latex-setup.md | LaTeX toolchain, VS Code LaTeX extensions, .latexmkrc, bib tools |
| terminal-setup.md | ~/.config/kitty/, ~/.config/tmux/, ~/.claude/keybindings.json, fish config |
| claude-usage-widget.md | ~/claude-projects/claude-usage/, SwiftBar plugin |
Check if the directory tree or other sections need updating."
jq -n --arg msg "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$msg}}'
