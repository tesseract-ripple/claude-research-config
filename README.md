# Claude Code Research Config

Claude Code configuration for academic math & cryptography research at RippleX Research.

Includes custom agents, skills (slash commands), end-of-day automation, a usage tracking widget, and a two-tier persistent memory system. See [`docs/claude-setup.md`](docs/claude-setup.md) for the full environment reference.

## What's in here

```
claude.md              # Global instructions (→ ~/.claude/CLAUDE.md)
settings.json          # Permissions, hooks, model default
keybindings.json       # Key bindings (currently default)
usage-config.json      # Spending cap & calibration

agents/                # 7 subagent definitions
  paper-reader.md        Summarize crypto/math papers (Sonnet)
  code-explorer.md       Navigate C++/Rust codebases (Haiku)
  code-reviewer.md       Review code for correctness (Sonnet)
  tex-checker.md         LaTeX grammar & notation (Sonnet)
  scientific-tex-editor.md  Scientific prose editing (Sonnet)
  journal-submission-checker.md  Pre-submission checks (Haiku)
  pdf-question-answerer.md  Answer questions about PDFs (Sonnet)

skills/                # 11 slash commands (/name in Claude Code)
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

tools/
  claude_usage.py        Real-time spending tracker (tmux + SwiftBar)

memory/
  MEMORY.md.template     Template for per-project memory files

docs/                    Detailed setup documentation
  claude-setup.md          Full environment reference
  claude-usage-widget.md   Usage widget docs
  latex-setup.md           LaTeX toolchain & style sheet
  terminal-setup.md        Kitty, tmux, fish, readline
```

## Quick start

```bash
git clone git@github.com:tesseract-ripple/claude-research-config.git ~/claude-research-config
cd ~/claude-research-config
./install.sh
```

The install script symlinks config files into `~/.claude/` and sets up the directory structure. It won't overwrite existing files — it backs them up first.

## Customization

After installing, edit files directly in the repo (or via the symlinks in `~/.claude/`). Changes are picked up by Claude Code on next session start.

Things you'll likely want to customize:
- **`settings.json`** — adjust permissions for your workflow
- **`claude.md`** — tailor the research focus and cost parameters
- **`usage-config.json`** — set your own monthly cap

## Auto-sync

If you ran `install.sh`, a launchd agent watches the repo for changes and auto-commits/pushes with descriptive messages. To disable:

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.claude.config-sync.plist
```

## Sources

- [Mitchell Hashimoto — My AI Adoption Journey](https://mitchellh.com/writing/my-ai-adoption-journey)
- [matsengrp/plugins](https://github.com/matsengrp/plugins) (MIT) — scientific-tex-editor, journal-submission-checker, pdf-question-answerer
- [pedrohcgs/claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow) (MIT) — compile-latex, proofread, lit-review, review-paper, validate-bib, research-ideation
- [Claude Code docs](https://code.claude.com/docs/en/costs)
