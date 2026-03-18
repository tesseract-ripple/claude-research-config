#!/bin/bash
# Stop hook: if config/docs were edited THIS session, block the stop and
# ask Claude to run a semantic audit before finishing.
# Uses session_id lines in the sentinel file so concurrent sessions don't interfere.
INPUT=$(cat)
sid=$(echo "$INPUT" | jq -r '.session_id // empty')
[ -z "$sid" ] && exit 0

sentinel="$HOME/.claude/hooks/sentinels/docs-edited-this-session"

if ! grep -qxF "$sid" "$sentinel" 2>/dev/null; then
  exit 0  # this session didn't edit any monitored files
fi

# Remove this session's entry BEFORE blocking so the audit's own edits
# (which are excluded from re-setting it) don't cause a loop.
# Also clean up the reminder-shown sentinel for this session.
sed -i '' "/^${sid}$/d" "$sentinel" 2>/dev/null
sed -i '' "/^${sid}$/d" "$HOME/.claude/hooks/sentinels/docs-reminder-shown" 2>/dev/null

# Remove empty sentinel files to avoid clutter
[ ! -s "$sentinel" ] && rm -f "$sentinel"
[ ! -s "$HOME/.claude/hooks/sentinels/docs-reminder-shown" ] && rm -f "$HOME/.claude/hooks/sentinels/docs-reminder-shown"

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
