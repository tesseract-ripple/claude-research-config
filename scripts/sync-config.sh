#!/bin/bash
# Auto-commit and push config changes.
# Runs on a 5-minute interval via launchd.
# Uses Claude (haiku, headless) to create logical commits with
# descriptive messages. Falls back to a simple bulk commit if
# Claude is unavailable. Push is always done by the script (not
# Claude) since git push is denied in Claude's global settings.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

# Only proceed if there are changes
if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
    exit 0
fi

# Try Claude for intelligent commit grouping
committed_by_claude=false
if command -v claude &>/dev/null; then
    PROMPT_FILE=$(mktemp /tmp/config-sync-prompt.XXXXXX)
    cat > "$PROMPT_FILE" <<'PROMPT'
You are in the claude-research-config repo. There are uncommitted changes.
Your job: create well-structured git commits with descriptive messages.

Rules:
- Run `git diff` and `git ls-files --others --exclude-standard` to see all changes.
- Group related changes into logical commits (e.g., all tmux changes together,
  all hook changes together, docs updates with the config they document).
- If all changes are small or closely related, a single commit is fine.
- Write clear commit messages: imperative mood, explain WHY not just WHAT.
  First line under 72 chars. Add a body paragraph for non-trivial changes.
- Use `git add <specific files>` to stage logically.
  Do NOT use `git add -A` unless everything belongs in one commit.
- Do NOT run `git push` — the caller script handles that.
- Do not amend existing commits. Only create new commits from uncommitted changes.
- Be concise. Do not explain what you're doing — just do it.
PROMPT

    claude --model haiku \
        --allowedTools 'Bash(git add:*)' \
        --allowedTools 'Bash(git commit:*)' \
        --allowedTools 'Bash(git diff:*)' \
        --allowedTools 'Bash(git status:*)' \
        --allowedTools 'Bash(git ls-files:*)' \
        --allowedTools 'Bash(git log:*)' \
        -p "$(cat "$PROMPT_FILE")" >> /tmp/claude-config-sync.log 2>&1 || true
    rm -f "$PROMPT_FILE"

    # Check if Claude committed everything
    if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
        committed_by_claude=true
    fi
fi

# Fallback: simple bulk commit (if Claude unavailable or left uncommitted changes)
if [[ "$committed_by_claude" != true ]]; then
    changed=$(git diff --name-only; git diff --cached --name-only; git ls-files --others --exclude-standard)
    changed=$(echo "$changed" | sort -u)

    msg_parts=()
    echo "$changed" | grep -q "^agents/" && msg_parts+=("agents")
    echo "$changed" | grep -q "^skills/" && msg_parts+=("skills")
    echo "$changed" | grep -q "^scripts/" && msg_parts+=("scripts")
    echo "$changed" | grep -q "^tools/" && msg_parts+=("tools")
    echo "$changed" | grep -q "^docs/" && msg_parts+=("docs")
    echo "$changed" | grep -q "claude\.md" && msg_parts+=("global instructions")
    echo "$changed" | grep -q "settings\.json" && msg_parts+=("settings")
    echo "$changed" | grep -q "keybindings" && msg_parts+=("keybindings")
    echo "$changed" | grep -q "usage-config" && msg_parts+=("usage config")

    if [[ ${#msg_parts[@]} -eq 0 ]]; then
        summary="Update config files"
    else
        summary="Update $(IFS=', '; echo "${msg_parts[*]}")"
    fi

    git add -A
    git commit -m "${summary}

Changed files: ${changed}"
fi

# Always push (script handles this, not Claude)
git push
