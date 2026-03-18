#!/bin/bash
# Stop hook: if config/docs were edited this session, block the stop and
# ask Claude to run a semantic audit before finishing.
# Gated by sentinel — silent if no config/docs were touched.
# The sentinel is removed on first fire to prevent infinite loops.
INPUT=$(cat)

sentinel="$HOME/.claude/hooks/sentinels/docs-edited-this-session"

if [ ! -f "$sentinel" ]; then
  exit 0
fi

# Remove sentinel BEFORE blocking so the audit's own edits
# (which are excluded from re-setting it) don't cause a loop
rm -f "$sentinel"

reason="DOCS SEMANTIC AUDIT: Config or docs files were edited this session. Before stopping, read each docs file in ~/claude-projects/docs/ and its corresponding config files, then fix any concrete discrepancies. Check for:
- Wrong values (numbers, paths, filenames that no longer match reality)
- Missing entries (new files, sentinels, features not yet documented)
- Stale descriptions (prose describing BEHAVIOR that has changed — not just renamed files, but changed semantics, removed mechanisms, new capabilities)
- Policy changes in CLAUDE.md that should be reflected in the relevant docs file (see the policy-trigger table in CLAUDE.md)

Pairs to check:
1. claude-setup.md vs ~/.claude/settings.json, ~/.claude/hooks/*.sh (ls), ~/.claude/agents/ (ls), ~/.claude/skills/ (ls)
2. terminal-setup.md vs ~/.config/tmux/tmux.conf, ~/.config/tmux/cheat.md
3. latex-setup.md vs ~/.latexmkrc, ~/.config/latexindent.yaml (if relevant files were edited)
4. claude-usage-widget.md (only if usage-related files were edited)
Skip pairs where no related files were touched. Report what you checked and any fixes made. If everything matches, say so briefly."

jq -n --arg reason "$reason" '{"decision":"block","reason":$reason}'
