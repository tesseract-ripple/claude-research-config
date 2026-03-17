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

# Mark that config/docs were touched this session (gates semantic check at Stop)
touch "$HOME/.claude/hooks/.docs-edited-this-session"

jq -n --arg msg "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$msg}}'
