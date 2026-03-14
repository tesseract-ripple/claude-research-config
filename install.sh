#!/bin/bash
# Install Claude research config and (optionally) dotfiles.
#
# Usage:
#   ./install.sh              # Interactive — asks what to install
#   ./install.sh --claude     # Just Claude Code config (default for coworkers)
#   ./install.sh --all        # Everything (full machine bootstrap)
#   ./install.sh --claude --terminal --latex   # Pick modules
#
# Modules:
#   --claude     Claude Code config (agents, skills, scripts, settings)
#   --terminal   Kitty, fish, tmux
#   --latex      crypto-math.sty, latexmkrc, latexindent, VSCode LaTeX snippets
#   --vscode     VSCode settings and keybindings
#   --git        gitconfig and global gitignore
#   --all        All of the above
#
# Safe: backs up any existing files to *.pre-repo before replacing them.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
PROJECTS_DIR="$HOME/claude-projects"
BACKUP_SUFFIX=".pre-repo"

# ── Helpers ──────────────────────────────────────────────────────────────────

log() { echo "[install] $*"; }

backup_and_link() {
    local target="$1" link="$2"
    local link_dir
    link_dir="$(dirname "$link")"
    [[ -d "$link_dir" ]] || mkdir -p "$link_dir"

    if [[ -L "$link" ]]; then
        rm "$link"
    elif [[ -e "$link" ]]; then
        log "Backing up $link → ${link}${BACKUP_SUFFIX}"
        mv "$link" "${link}${BACKUP_SUFFIX}"
    fi
    ln -s "$target" "$link"
    log "  $link → $target"
}

# ── Module installers ────────────────────────────────────────────────────────

install_claude() {
    log "Installing Claude Code config..."
    mkdir -p "$CLAUDE_DIR"

    backup_and_link "$REPO_DIR/claude.md"          "$CLAUDE_DIR/CLAUDE.md"
    backup_and_link "$REPO_DIR/settings.json"      "$CLAUDE_DIR/settings.json"
    backup_and_link "$REPO_DIR/keybindings.json"   "$CLAUDE_DIR/keybindings.json"
    backup_and_link "$REPO_DIR/usage-config.json"  "$CLAUDE_DIR/usage-config.json"
    backup_and_link "$REPO_DIR/agents"             "$CLAUDE_DIR/agents"
    backup_and_link "$REPO_DIR/skills"             "$CLAUDE_DIR/skills"
    backup_and_link "$REPO_DIR/scripts"            "$CLAUDE_DIR/scripts"

    # Usage widget
    mkdir -p "$PROJECTS_DIR/claude-usage"
    backup_and_link "$REPO_DIR/tools/claude_usage.py" "$PROJECTS_DIR/claude-usage/claude_usage.py"

    # SwiftBar plugin (if SwiftBar is installed)
    if [[ -d "$HOME/.config/swiftbar" ]] || command -v swiftbar &>/dev/null; then
        mkdir -p "$HOME/.config/swiftbar"
        backup_and_link "$REPO_DIR/tools/swiftbar/claude-usage.60s.py" "$HOME/.config/swiftbar/claude-usage.60s.py"
    fi

    # Docs
    mkdir -p "$PROJECTS_DIR/docs"
    for doc in "$REPO_DIR/docs/"*.md; do
        name=$(basename "$doc")
        backup_and_link "$doc" "$PROJECTS_DIR/docs/$name"
    done

    # Working directories
    mkdir -p "$PROJECTS_DIR"/{papers-inbox,eod-reports}
    touch "$PROJECTS_DIR/explore-prompts.txt" 2>/dev/null || true

    log "Claude Code config installed."
}

install_terminal() {
    log "Installing terminal config (kitty, fish, tmux)..."

    # Kitty
    mkdir -p "$HOME/.config/kitty"
    backup_and_link "$REPO_DIR/dotfiles/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"

    # Fish
    mkdir -p "$HOME/.config/fish/functions" "$HOME/.config/fish/conf.d"
    backup_and_link "$REPO_DIR/dotfiles/fish/config.fish"          "$HOME/.config/fish/config.fish"
    backup_and_link "$REPO_DIR/dotfiles/fish/fish_plugins"         "$HOME/.config/fish/fish_plugins"
    backup_and_link "$REPO_DIR/dotfiles/fish/conf.d/omf.fish"      "$HOME/.config/fish/conf.d/omf.fish"
    backup_and_link "$REPO_DIR/dotfiles/fish/functions/cat.fish"   "$HOME/.config/fish/functions/cat.fish"
    backup_and_link "$REPO_DIR/dotfiles/fish/functions/vim.fish"   "$HOME/.config/fish/functions/vim.fish"

    # tmux
    if command -v tmux &>/dev/null; then
        mkdir -p "$HOME/.config/tmux"
        backup_and_link "$REPO_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
        backup_and_link "$REPO_DIR/tmux/cheat.md"  "$HOME/.config/tmux/cheat.md"
    fi

    log "Terminal config installed."
    log "  Note: Run 'fisher update' after installing fish plugins."
    log "  Note: Install font 'DaddyTimeMono Nerd Font Mono' for kitty."
}

install_latex() {
    log "Installing LaTeX config..."

    # Style sheet → local TEXMF tree
    local texmf_dir="$HOME/Library/texmf/tex/latex/local"
    if [[ "$(uname)" != "Darwin" ]]; then
        texmf_dir="$HOME/texmf/tex/latex/local"
    fi
    mkdir -p "$texmf_dir"
    backup_and_link "$REPO_DIR/dotfiles/latex/crypto-math.sty" "$texmf_dir/crypto-math.sty"

    # latexmkrc
    backup_and_link "$REPO_DIR/dotfiles/latex/latexmkrc" "$HOME/.latexmkrc"

    # latexindent config
    mkdir -p "$HOME/.config"
    backup_and_link "$REPO_DIR/dotfiles/latex/latexindent.yaml" "$HOME/.config/latexindent.yaml"

    # Template and snippets in ~/.config/latex-export/
    mkdir -p "$HOME/.config/latex-export"
    backup_and_link "$REPO_DIR/dotfiles/latex/crypto-math.sty" "$HOME/.config/latex-export/crypto-math.sty"
    backup_and_link "$REPO_DIR/dotfiles/latex/template.tex"    "$HOME/.config/latex-export/template.tex"
    backup_and_link "$REPO_DIR/dotfiles/latex/latex.json"      "$HOME/.config/latex-export/latex.json"

    # VSCode snippets (only the LaTeX snippet, not full VSCode config)
    local vscode_snippets="$HOME/Library/Application Support/Code/User/snippets"
    if [[ -d "$vscode_snippets" ]] || [[ -d "$HOME/Library/Application Support/Code" ]]; then
        mkdir -p "$vscode_snippets"
        backup_and_link "$REPO_DIR/dotfiles/latex/latex.json" "$vscode_snippets/latex.json"
    fi

    # Update TEXMF database
    if command -v mktexlsr &>/dev/null; then
        mktexlsr "$texmf_dir/.." 2>/dev/null || true
    fi

    log "LaTeX config installed."
    log "  Verify with: kpsewhich crypto-math.sty"
}

install_vscode() {
    log "Installing VSCode config..."
    local vscode_user="$HOME/Library/Application Support/Code/User"
    if [[ "$(uname)" != "Darwin" ]]; then
        vscode_user="$HOME/.config/Code/User"
    fi

    if [[ -d "$(dirname "$vscode_user")" ]]; then
        mkdir -p "$vscode_user"
        backup_and_link "$REPO_DIR/dotfiles/vscode/settings.json"    "$vscode_user/settings.json"
        backup_and_link "$REPO_DIR/dotfiles/vscode/keybindings.json" "$vscode_user/keybindings.json"
        log "VSCode config installed."
    else
        log "VSCode not found, skipping."
    fi
}

install_git() {
    log "Installing git config..."
    backup_and_link "$REPO_DIR/dotfiles/git/gitconfig" "$HOME/.gitconfig"
    mkdir -p "$HOME/.config/git"
    backup_and_link "$REPO_DIR/dotfiles/git/ignore"    "$HOME/.config/git/ignore"
    log "Git config installed."
    log "  Note: Update name/email in ~/.gitconfig for your identity."
}

install_autosync() {
    if [[ "$(uname)" != "Darwin" ]]; then return; fi

    local plist_name="com.claude.config-sync"
    local plist_path="$HOME/Library/LaunchAgents/${plist_name}.plist"
    local sync_script="$REPO_DIR/scripts/sync-config.sh"

    if [[ ! -f "$sync_script" ]]; then return; fi

    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$plist_path" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${plist_name}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${sync_script}</string>
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
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
PLISTEOF
    launchctl bootout "gui/$(id -u)" "$plist_path" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$plist_path"
    log "Auto-sync enabled (commits & pushes every 5 minutes)."
}

# ── Interactive menu ─────────────────────────────────────────────────────────

ask() {
    local prompt="$1" default="${2:-n}"
    local yn
    if [[ "$default" == "y" ]]; then
        printf "%s [Y/n] " "$prompt"
    else
        printf "%s [y/N] " "$prompt"
    fi
    read -r yn
    yn="${yn:-$default}"
    [[ "$yn" =~ ^[Yy] ]]
}

run_interactive() {
    echo ""
    echo "┌──────────────────────────────────────────────┐"
    echo "│   Claude Research Config — Interactive Setup  │"
    echo "└──────────────────────────────────────────────┘"
    echo ""
    echo "This will symlink config files from this repo into"
    echo "their expected locations. Existing files are backed up."
    echo ""

    # Claude is always installed
    install_claude

    echo ""
    if ask "Install terminal config? (kitty, fish, tmux)"; then
        install_terminal
    fi

    echo ""
    if ask "Install LaTeX config? (crypto-math.sty, latexmkrc, snippets)"; then
        install_latex
    fi

    echo ""
    if ask "Install VSCode settings?"; then
        install_vscode
    fi

    echo ""
    if ask "Install git config? (gitconfig, global ignore)"; then
        install_git
    fi

    echo ""
    if ask "Enable auto-sync? (auto-commit & push changes every 5 min)"; then
        install_autosync
    fi
}

# ── CLI argument parsing ─────────────────────────────────────────────────────

main() {
    local do_claude=false do_terminal=false do_latex=false
    local do_vscode=false do_git=false do_sync=false
    local has_args=false

    for arg in "$@"; do
        has_args=true
        case "$arg" in
            --claude)    do_claude=true ;;
            --terminal)  do_terminal=true ;;
            --latex)     do_latex=true ;;
            --vscode)    do_vscode=true ;;
            --git)       do_git=true ;;
            --sync)      do_sync=true ;;
            --all)       do_claude=true; do_terminal=true; do_latex=true
                         do_vscode=true; do_git=true; do_sync=true ;;
            -h|--help)
                echo "Usage: install.sh [--claude] [--terminal] [--latex] [--vscode] [--git] [--sync] [--all]"
                echo ""
                echo "  No arguments → interactive mode"
                echo "  --claude     Claude Code config (agents, skills, scripts, usage widget)"
                echo "  --terminal   Kitty, fish shell, tmux"
                echo "  --latex      crypto-math.sty, latexmkrc, latexindent, VSCode LaTeX snippets"
                echo "  --vscode     VSCode settings and keybindings"
                echo "  --git        gitconfig and global gitignore"
                echo "  --sync       Auto-commit & push via launchd (macOS)"
                echo "  --all        Everything above"
                exit 0
                ;;
            *)
                echo "Unknown option: $arg (try --help)"
                exit 1
                ;;
        esac
    done

    if ! $has_args; then
        run_interactive
    else
        $do_claude   && install_claude
        $do_terminal && install_terminal
        $do_latex    && install_latex
        $do_vscode   && install_vscode
        $do_git      && install_git
        $do_sync     && install_autosync
    fi

    echo ""
    log "Done! Restart Claude Code / terminal to pick up changes."
}

main "$@"
