#!/bin/bash
# Stop hook: if config/docs were edited this session, inject a semantic
# audit prompt into context. Claude will read the docs and configs,
# compare them, and fix any discrepancies before fully stopping.
# Gated by sentinel — silent if no config/docs were touched.
sentinel="$HOME/.claude/hooks/.docs-edited-this-session"
if [ ! -f "$sentinel" ]; then
  exit 0
fi

# Clean up sentinel
rm -f "$sentinel"

msg="DOCS SEMANTIC AUDIT: Config or docs files were edited this session. Before stopping, read each docs file in ~/claude-projects/docs/ and its corresponding config files, then fix any concrete discrepancies (wrong values, missing entries, stale descriptions). Check:
1. claude-setup.md vs ~/.claude/settings.json, ~/.claude/hooks/*.sh (ls), ~/.claude/agents/ (ls), ~/.claude/skills/ (ls)
2. terminal-setup.md vs ~/.config/tmux/tmux.conf, ~/.config/tmux/cheat.md
3. latex-setup.md vs ~/.latexmkrc, ~/.config/latexindent.yaml (if relevant files were edited)
4. claude-usage-widget.md (only if usage-related files were edited)
Skip pairs where no related files were touched. Report what you checked and any fixes made. If everything matches, say so briefly."

jq -n --arg msg "$msg" '{systemMessage:$msg}'
