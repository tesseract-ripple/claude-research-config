#!/bin/bash
# SessionStart hook: check docs against actual filesystem state.
# Pure filesystem checks — no LLM calls, no API calls.
# Silent when everything matches; outputs discrepancies as additionalContext.

docs_dir="$HOME/claude-projects/docs"
setup_doc="$docs_dir/claude-setup.md"
terminal_doc="$docs_dir/terminal-setup.md"
issues=""

add_issue() {
  if [ -n "$issues" ]; then
    issues="$issues\n- $1"
  else
    issues="- $1"
  fi
}

# --- claude-setup.md checks ---

if [ -f "$setup_doc" ]; then
  # 1. Check ~/claude-projects/ directories against docs tree
  actual_dirs=$(ls -1d "$HOME/claude-projects"/*/ 2>/dev/null | xargs -I{} basename {} | sort)
  for dir in $actual_dirs; do
    # Skip docs/ itself and transient files
    case "$dir" in
      docs) continue ;;
    esac
    if ! grep -q "$dir" "$setup_doc" 2>/dev/null; then
      add_issue "claude-setup.md: ~/claude-projects/$dir/ exists but is not in docs directory tree"
    fi
  done

  # 2. Check ~/.claude/hooks/ scripts against docs
  actual_hooks=$(ls -1 "$HOME/.claude/hooks/"*.sh 2>/dev/null | xargs -I{} basename {})
  for script in $actual_hooks; do
    if ! grep -q "$script" "$setup_doc" 2>/dev/null; then
      add_issue "claude-setup.md: ~/.claude/hooks/$script exists but is not documented"
    fi
  done

  # 3. Check ~/.claude/agents/ against docs
  actual_agents=$(ls -1 "$HOME/.claude/agents/"*.md 2>/dev/null | xargs -I{} basename {})
  for agent in $actual_agents; do
    if ! grep -q "$agent" "$setup_doc" 2>/dev/null; then
      add_issue "claude-setup.md: ~/.claude/agents/$agent exists but is not documented"
    fi
  done

  # 4. Check ~/.claude/skills/ against docs
  actual_skills=$(ls -1d "$HOME/.claude/skills"/*/ 2>/dev/null | xargs -I{} basename {})
  for skill in $actual_skills; do
    if ! grep -q "$skill" "$setup_doc" 2>/dev/null; then
      add_issue "claude-setup.md: ~/.claude/skills/$skill/ exists but is not documented"
    fi
  done

  # 5. Check ~/.claude/scripts/ against docs
  actual_scripts=$(ls -1 "$HOME/.claude/scripts/"* 2>/dev/null | xargs -I{} basename {})
  for script in $actual_scripts; do
    if ! grep -q "$script" "$setup_doc" 2>/dev/null; then
      add_issue "claude-setup.md: ~/.claude/scripts/$script exists but is not documented"
    fi
  done

  # 6. Check symlinks are still valid
  for link in "$HOME/.claude/CLAUDE.md" "$HOME/.claude/settings.json" "$HOME/.claude/agents" "$HOME/.claude/keybindings.json"; do
    if [ -L "$link" ]; then
      target=$(readlink "$link")
      if [ ! -e "$link" ]; then
        add_issue "claude-setup.md: symlink $(basename "$link") -> $target is BROKEN"
      fi
    fi
  done

  # 7. Check hook event count in settings.json matches docs
  if command -v jq &>/dev/null && [ -f "$HOME/.claude/settings.json" ]; then
    settings_hook_count=$(jq '.hooks | length' "$HOME/.claude/settings.json" 2>/dev/null)
    docs_hook_mentions=$(grep -cE '^\- \*\*[A-Za-z]+' "$setup_doc" 2>/dev/null | head -1)
    # Just check if settings has hooks not mentioned in docs
    settings_events=$(jq -r '.hooks | keys[]' "$HOME/.claude/settings.json" 2>/dev/null)
    for event in $settings_events; do
      if ! grep -q "$event" "$setup_doc" 2>/dev/null; then
        add_issue "claude-setup.md: hook event '$event' is in settings.json but not documented"
      fi
    done
  fi
fi

# --- terminal-setup.md checks ---

if [ -f "$terminal_doc" ] && [ -f "$HOME/.config/tmux/tmux.conf" ]; then
  # Check that key tmux bindings in config are mentioned in docs
  # Look for bind commands that aren't standard/obvious
  if grep -q "repeat-time" "$HOME/.config/tmux/tmux.conf" 2>/dev/null; then
    repeat_val=$(grep "repeat-time" "$HOME/.config/tmux/tmux.conf" | grep -oE '[0-9]+')
    if [ -n "$repeat_val" ] && ! grep -q "$repeat_val" "$terminal_doc" 2>/dev/null; then
      add_issue "terminal-setup.md: tmux repeat-time is $repeat_val but docs show a different value"
    fi
  fi
fi

# --- Output ---

if [ -n "$issues" ]; then
  msg="DOCS STALENESS CHECK: Found discrepancies between docs and actual filesystem:\n$issues\nPlease fix these in ~/claude-projects/docs/ before doing other work, or note them for later if they're intentional."
  jq -n --arg msg "$msg" '{systemMessage:$msg}'
fi
