# Claude Code Research Config

Claude Code configuration for academic math & cryptography research at RippleX Research, plus optional dotfiles for the full terminal/editor/LaTeX environment.

## Quick start

**Just Claude Code config** (recommended for coworkers):
```bash
git clone git@github.com:tesseract-ripple/claude-research-config.git ~/claude-research-config
cd ~/claude-research-config
./install.sh --claude
```

**Full machine bootstrap** (everything):
```bash
./install.sh --all
```

**Interactive** (pick what you want):
```bash
./install.sh
```

The install script symlinks files from the repo into their expected locations. Existing files are backed up to `*.pre-repo`. Edits to either the repo or the target location update the same file.

## Modules

| Flag | What it installs | Target locations |
|------|-----------------|------------------|
| `--claude` | Agents, skills, scripts, settings, usage widget | `~/.claude/`, `~/claude-projects/` |
| `--terminal` | Kitty, fish shell, tmux | `~/.config/kitty/`, `~/.config/fish/`, `~/.config/tmux/` |
| `--latex` | crypto-math.sty, latexmkrc, latexindent, VSCode snippets | `~/Library/texmf/`, `~/.latexmkrc`, `~/.config/` |
| `--vscode` | Editor settings and keybindings | `~/Library/Application Support/Code/User/` |
| `--git` | gitconfig and global gitignore | `~/.gitconfig`, `~/.config/git/` |
| `--sync` | Auto-commit & push every 5 min (launchd) | `~/Library/LaunchAgents/` |
| `--all` | Everything above | |

With no arguments, the installer runs interactively: it always installs Claude config, then asks about each optional module.

## What's in here

```
# ── Claude Code (--claude) ──────────────────────────────────────────
claude.md              Global instructions (→ ~/.claude/CLAUDE.md)
settings.json          Permissions, hooks, model default
keybindings.json       Key bindings
usage-config.json      Spending cap & calibration

agents/                7 subagent definitions
  paper-reader.md        Summarize crypto/math papers (Sonnet)
  code-explorer.md       Navigate C++/Rust codebases (Haiku)
  code-reviewer.md       Review code for correctness (Sonnet)
  tex-checker.md         LaTeX grammar & notation (Sonnet)
  scientific-tex-editor.md  Scientific prose editing (Sonnet)
  journal-submission-checker.md  Pre-submission checks (Haiku)
  pdf-question-answerer.md  Answer questions about PDFs (Sonnet)

skills/                11 slash commands (/name in Claude Code)
  prove/                 Construct or verify a proof
  verify/                Computational verification (sympy, etc.)
  survey/                Topic survey with comparison table
  research-ideation/     Generate research directions
  writeup/               Draft LaTeX sections
  compile-latex/         Compile with bibtex (3-pass)
  proofread/             Grammar & notation report
  lit-review/            Structured literature search
  review-paper/          Referee-style manuscript review
  validate-bib/          Cross-reference citations vs .bib
  help-research/         Cheat sheet of all commands

scripts/
  eod-agents.sh          End-of-day batch runner (triage, papers, review, explore)
  sync-config.sh         Auto-commit & push on changes (via launchd)

tools/
  claude_usage.py        Real-time spending tracker (core script)
  swiftbar/
    claude-usage.60s.py  SwiftBar menu bar plugin

memory/
  MEMORY.md.template     Template for per-project memory files

docs/                  Detailed setup documentation
  claude-setup.md        Full environment reference
  claude-usage-widget.md Usage widget docs
  latex-setup.md         LaTeX toolchain & style sheet
  terminal-setup.md      Kitty, tmux, fish, readline

# ── Terminal (--terminal) ───────────────────────────────────────────
tmux/
  tmux.conf              Ctrl+Space prefix, usage widget in status bar
  cheat.md               Popup cheatsheet (tmux, readline, Amethyst)

dotfiles/kitty/
  kitty.conf             Neon Orchid theme, DaddyTimeMono Nerd Font, Option-as-Alt

dotfiles/fish/
  config.fish            Bobthefish theme, vim keybindings, auto-tmux, pyenv
  fish_plugins           Fisher plugin list (fisher, bobthefish)
  conf.d/omf.fish        Oh My Fish init
  functions/cat.fish     cat → bat alias
  functions/vim.fish     vim → nvim alias

# ── LaTeX (--latex) ─────────────────────────────────────────────────
dotfiles/latex/
  crypto-math.sty        Master style sheet (450+ lines of packages & macros)
  template.tex           Full paper template using crypto-math.sty
  latex.json             VSCode snippets (cryptopaper, thm, lem, defn, alg, ...)
  latexindent.yaml       Hard-wrap prose at 100 columns
  latexmkrc              pdflatex + biber, synctex

# ── VSCode (--vscode) ──────────────────────────────────────────────
dotfiles/vscode/
  settings.json          Noctis Bordo theme, LaTeX Workshop, JetBrains Mono
  keybindings.json       Shift+Enter → ESC+Enter in terminal (vim mode)

# ── Git (--git) ─────────────────────────────────────────────────────
dotfiles/git/
  gitconfig              User identity
  ignore                 Global gitignore (.claude/settings.local.json)
```

## Customization

After installing, edit files directly in the repo (or via their symlinked locations). Changes are picked up on next app/session start.

Things you'll likely want to customize:
- **`claude.md`** — tailor the research focus, cost parameters, memory system
- **`settings.json`** — adjust Claude Code permissions for your workflow
- **`dotfiles/git/gitconfig`** — your name and email
- **`dotfiles/vscode/settings.json`** — theme, fonts, extensions
- **`dotfiles/kitty/kitty.conf`** — terminal colors and font

## Prerequisites

Depending on which modules you install:

| Module | Requires |
|--------|----------|
| Claude | `claude` CLI |
| Terminal | `kitty`, `fish`, `tmux`, `bat`, `nvim`, `glow` (for cheatsheet popup) |
| LaTeX | MacTeX or TeX Live, `latexindent`, `biber` |
| VSCode | VS Code with extensions: LaTeX Workshop, LTeX, Noctis |
| Git | `git` |

Install most dependencies via Homebrew:
```bash
brew install fish tmux bat neovim glow pyenv
brew install --cask kitty visual-studio-code
```

## Auto-sync

The `--sync` module installs a launchd agent that checks for changes every 5 minutes and auto-commits/pushes with descriptive messages. To disable:

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.claude.config-sync.plist
```

Logs: `/tmp/claude-config-sync.log`

## Sources

- [Mitchell Hashimoto — My AI Adoption Journey](https://mitchellh.com/writing/my-ai-adoption-journey)
- [matsengrp/plugins](https://github.com/matsengrp/plugins) (MIT) — scientific-tex-editor, journal-submission-checker, pdf-question-answerer
- [pedrohcgs/claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow) (MIT) — compile-latex, proofread, lit-review, review-paper, validate-bib, research-ideation
- [Claude Code docs](https://code.claude.com/docs/en/costs)
