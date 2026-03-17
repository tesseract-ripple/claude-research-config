#!/bin/bash
# PostToolUse hook on Bash: remind about docs when commands create/modify
# files in monitored directories. Silent for all other Bash commands.
cmd=$(jq -r '.tool_input.command // empty')

# Only trigger on commands that create, copy, move, or clone into monitored paths
# Check for structural commands first
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

sentinel="$HOME/.claude/hooks/.docs-edited-this-session"
audit_done="$HOME/.claude/hooks/.docs-audit-done"

# If the audit already ran this session, stay silent — no more reminders or sentinel writes
[ -f "$audit_done" ] && exit 0

# Commands targeting docs/ itself are the audit — don't re-trigger the sentinel
case "$cmd" in
  *claude-projects/docs/*) exit 0 ;;
esac

# First qualifying command: show reminder and set sentinel for Stop audit
# Subsequent commands: silently ensure sentinel exists, skip the reminder
if [ -f "$sentinel" ]; then
  exit 0
fi

touch "$sentinel"
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
