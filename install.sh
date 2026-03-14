#!/bin/bash
# Install Claude research config by symlinking into ~/.claude/
# Safe: backs up any existing files before replacing them.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
PROJECTS_DIR="$HOME/claude-projects"
BACKUP_SUFFIX=".pre-repo"

log() { echo "[install] $*"; }

backup_and_link() {
    local target="$1" link="$2"
    if [[ -L "$link" ]]; then
        rm "$link"
    elif [[ -e "$link" ]]; then
        log "Backing up $link → ${link}${BACKUP_SUFFIX}"
        mv "$link" "${link}${BACKUP_SUFFIX}"
    fi
    ln -s "$target" "$link"
    log "Linked $link → $target"
}

# Ensure ~/.claude exists
mkdir -p "$CLAUDE_DIR"

# Core config files
backup_and_link "$REPO_DIR/claude.md"          "$CLAUDE_DIR/CLAUDE.md"
backup_and_link "$REPO_DIR/settings.json"      "$CLAUDE_DIR/settings.json"
backup_and_link "$REPO_DIR/keybindings.json"   "$CLAUDE_DIR/keybindings.json"
backup_and_link "$REPO_DIR/usage-config.json"  "$CLAUDE_DIR/usage-config.json"

# Directories
backup_and_link "$REPO_DIR/agents"   "$CLAUDE_DIR/agents"
backup_and_link "$REPO_DIR/skills"   "$CLAUDE_DIR/skills"
backup_and_link "$REPO_DIR/scripts"  "$CLAUDE_DIR/scripts"

# Optional: usage widget
if [[ -d "$PROJECTS_DIR/claude-usage" ]]; then
    backup_and_link "$REPO_DIR/tools/claude_usage.py" "$PROJECTS_DIR/claude-usage/claude_usage.py"
    log "Linked usage widget"
fi

# Optional: docs
if [[ -d "$PROJECTS_DIR/docs" ]]; then
    for doc in "$REPO_DIR/docs/"*.md; do
        name=$(basename "$doc")
        backup_and_link "$doc" "$PROJECTS_DIR/docs/$name"
    done
    log "Linked docs"
fi

# Create working directories
mkdir -p "$PROJECTS_DIR"/{papers-inbox,eod-reports}
touch "$PROJECTS_DIR/explore-prompts.txt" 2>/dev/null || true

# Set up auto-sync (launchd agent for macOS)
PLIST_NAME="com.claude.config-sync"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"
SYNC_SCRIPT="$REPO_DIR/scripts/sync-config.sh"

if [[ "$(uname)" == "Darwin" && -f "$SYNC_SCRIPT" ]]; then
    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$PLIST_PATH" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${SYNC_SCRIPT}</string>
    </array>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>WorkingDirectory</key>
    <string>${REPO_DIR}</string>
    <key>StandardOutPath</key>
    <string>/tmp/claude-config-sync.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/claude-config-sync.log</string>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLISTEOF
    launchctl bootout "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"
    log "Auto-sync enabled (every 5 minutes)"
fi

log "Done! Restart Claude Code to pick up changes."
