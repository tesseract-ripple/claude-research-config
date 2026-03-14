#!/bin/bash
# Auto-commit and push config changes.
# Runs on a 5-minute interval via launchd.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

# Only proceed if there are changes
if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
    exit 0
fi

# Build a descriptive commit message from changed files
changed=$(git diff --name-only; git diff --cached --name-only; git ls-files --others --exclude-standard)
changed=$(echo "$changed" | sort -u)

# Categorize changes
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

# Count files changed
n_files=$(echo "$changed" | wc -l | tr -d ' ')
details="Changed files: $changed"

git add -A
git commit -m "$(cat <<EOF
${summary}

${details}
EOF
)"
git push
