#!/bin/bash
# Stop hook: if config/docs were edited this session, block the stop and
# ask Claude to run a semantic audit before finishing.
# Gated by sentinel — silent if no config/docs were touched.
# The sentinel is removed on first fire to prevent infinite loops.
INPUT=$(cat)

sentinel="$HOME/.claude/hooks/.docs-edited-this-session"
audit_done="$HOME/.claude/hooks/.docs-audit-done"

if [ ! -f "$sentinel" ]; then
  exit 0
fi

# If audit already ran this session, don't block again
if [ -f "$audit_done" ]; then
  exit 0
fi

# Mark audit as done BEFORE blocking — prevents re-trigger even if
# the audit itself edits monitored files that recreate the sentinel
touch "$audit_done"
rm -f "$sentinel"

reason="DOCS SEMANTIC AUDIT: Config or docs files were edited this session. Before stopping, read each docs file in ~/claude-projects/docs/ and its corresponding config files, then fix any concrete discrepancies (wrong values, missing entries, stale descriptions). Check:
1. claude-setup.md vs ~/.claude/settings.json, ~/.claude/hooks/*.sh (ls), ~/.claude/agents/ (ls), ~/.claude/skills/ (ls)
2. terminal-setup.md vs ~/.config/tmux/tmux.conf, ~/.config/tmux/cheat.md
3. latex-setup.md vs ~/.latexmkrc, ~/.config/latexindent.yaml (if relevant files were edited)
4. claude-usage-widget.md (only if usage-related files were edited)
Skip pairs where no related files were touched. Report what you checked and any fixes made. If everything matches, say so briefly."

jq -n --arg reason "$reason" '{"decision":"block","reason":$reason}'
