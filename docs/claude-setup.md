# Claude Code Research Environment Setup

**Date:** 2026-02-11
**Account:** Enterprise plan, $480 spending cap, Opus 4.6 default model

## Architecture

All configuration lives directly in `~/.claude/`, which is where Claude Code reads it. Edit files there and restart `claude` to pick up changes.

```
~/.claude/                           # All config lives here
├── CLAUDE.md                        # Global agent instructions
├── memory/
│   └── MEMORY.md                    # Global memory (auto-maintained)
├── settings.json                    # Model, permissions, hooks
├── agents/                          # Subagent definitions
│   ├── paper-reader.md              # Sonnet — paper summarization
│   ├── code-explorer.md             # Haiku — codebase navigation
│   ├── code-reviewer.md             # Sonnet — code review
│   ├── tex-checker.md               # Sonnet — LaTeX checking
│   ├── scientific-tex-editor.md     # Sonnet — scientific editing
│   ├── journal-submission-checker.md # Haiku — pre-submission checks
│   └── pdf-question-answerer.md     # Sonnet — PDF analysis
├── skills/                          # Slash commands (invoke with /name)
│   ├── help-research/SKILL.md       # /help-research — this cheat sheet
│   ├── prove/SKILL.md               # /prove — construct/verify proofs
│   ├── verify/SKILL.md              # /verify — computational verification
│   ├── survey/SKILL.md              # /survey — topic survey with table
│   ├── writeup/SKILL.md             # /writeup — LaTeX drafting
│   ├── compile-latex/SKILL.md       # /compile-latex — compile with bibtex
│   ├── proofread/SKILL.md           # /proofread — grammar/notation check
│   ├── lit-review/SKILL.md          # /lit-review — structured lit review
│   ├── review-paper/SKILL.md        # /review-paper — referee-style review
│   ├── validate-bib/SKILL.md        # /validate-bib — citation validation
│   └── research-ideation/SKILL.md   # /research-ideation — idea generation
├── projects/                        # Per-project CLAUDE.md (shadow dirs, auto-created)
└── scripts/
    └── eod-agents.sh                # End-of-day batch runner

~/claude-projects/                   # Working directory for Claude-visible repos
├── confidential-transactions/       # CT research (LaTeX, PDFs, bib)
│   └── MEMORY.md                    # Project memory (auto-maintained)
├── rippled/                         # xrplf/rippled checkout
├── papers-inbox/                    # Drop PDFs here for EOD processing
├── eod-reports/                     # Daily reports from eod-agents.sh
├── explore-prompts.txt              # Research questions for EOD exploration
├── papers -> ~/Documents/papers     # Symlink to papers library
├── zotero -> ~/Zotero               # Symlink to Zotero database
└── docs/                            # This documentation (auto-updated)
```

## MCP Servers

| Server | Scope | Purpose |
|---|---|---|
| `MCP_DOCKER` | user | Docker-based MCP gateway (pre-existing) |
| `filesystem` | user | Read/write access to `~/claude-projects/` only |

The filesystem server gives Claude direct file access to everything under `~/claude-projects/`.

## Settings

### Model
Default: `opus`. Use `/model sonnet` or `/model haiku` in-session for cheaper tasks.

### Permissions

**Auto-allowed (no prompt):**
- Python, SageMath, LaTeX, C/C++ compilation
- Git read-only operations (log, diff, status, show)
- File reading, search, web search

**Auto-denied:**
- `rm -rf`, `git push`, `git checkout --`, `git reset --hard`
- Reading `.env` files or `secrets/` directories

**Prompted (requires confirmation):**
- Everything else (git commit, file writes, etc.)

### Hooks

- **Notification**: macOS notification + sound when Claude needs input
- **Stop**: macOS notification when a task finishes

These support the Hashimoto workflow pattern: run agents in the background, don't context-switch, check results during natural breaks.

## Subagents (7 total)

Agents are invoked automatically by Claude when relevant, or manually via the Task tool.

| Agent | Model | Cost Tier | Purpose |
|---|---|---|---|
| `paper-reader` | Sonnet | $$ | Summarize crypto/math papers |
| `code-explorer` | Haiku | $ | Navigate C++/Rust codebases |
| `code-reviewer` | Sonnet | $$ | Review code for correctness/safety |
| `tex-checker` | Sonnet | $$ | Check LaTeX grammar/notation |
| `scientific-tex-editor` | Sonnet | $$ | Deep scientific editing |
| `journal-submission-checker` | Haiku | $ | Pre-submission quality gate |
| `pdf-question-answerer` | Sonnet | $$ | Answer questions about PDFs |

### Cost rationale
- Haiku (~1/15 Opus cost): mechanical tasks (file scanning, link checking, codebase search)
- Sonnet (~1/5 Opus cost): tasks needing understanding but not deep reasoning
- Opus: reserved for main session — proofs, complex math, novel research

## Skills / Slash Commands (11 total)

Invoke these with `/command-name` in Claude Code.

### Math & Crypto Research
| Command | Purpose |
|---|---|
| `/prove <claim>` | Construct or verify a mathematical proof |
| `/verify <expression>` | Computationally verify an identity or property |
| `/survey <topic>` | Survey a research area with comparison table |
| `/research-ideation <topic>` | Generate research directions and conjectures |

### Paper Writing
| Command | Purpose |
|---|---|
| `/writeup <section>` | Draft LaTeX matching existing document style |
| `/compile-latex <file.tex>` | Compile with bibtex, report warnings |
| `/proofread <file or 'all'>` | Grammar/notation check (report only, no edits) |
| `/validate-bib [file.bib]` | Cross-reference citations vs bibliography |

### Paper Reading
| Command | Purpose |
|---|---|
| `/lit-review <topic>` | Structured literature search with BibTeX output |
| `/review-paper <file>` | Referee-style manuscript review |

### Meta
| Command | Purpose |
|---|---|
| `/help-research` | Show cheat sheet of all commands and agents |

## End-of-Day Workflow

### Setup
```bash
# Add to your shell profile for convenience:
alias eod='~/.claude/scripts/eod-agents.sh'
```

### Usage
```bash
eod                    # Run all tasks (triage, papers, review, explore)
eod papers             # Only process papers inbox
eod triage explore     # Only triage and exploration
```

### Tasks

**triage** — For each git repo in `~/claude-projects/`, uses `gh` to list open issues/PRs and produces an effort/value triage report.

**papers** — Processes any PDFs in `~/claude-projects/papers-inbox/`, produces structured summaries, moves processed files to `papers-inbox/processed/`.

**review** — For repos with commits in the last 24 hours, reviews the diff for correctness and safety issues.

**explore** — Reads research prompts from `~/claude-projects/explore-prompts.txt` (one per line, `#` for comments) and runs each as an independent Claude session. Clears the file after processing.

### Output
Reports are written to `~/claude-projects/eod-reports/YYYY-MM-DD/`. A macOS notification fires when all tasks complete.

### Example explore-prompts.txt
```
# Research directions for tonight
Survey recent advances in lattice-based range proofs since 2023. Compare proof sizes and assumptions. Focus on constructions compatible with Pedersen commitments.
Find all implementations of Bulletproofs in C or C++ with permissive licenses. For each, note: language, LOC, supported curves, license, last commit date.
```

## Persistent Memory System

Claude maintains memory files to preserve context across sessions without re-deriving past conclusions.

### Two tiers

| Tier | File | Scope | Contents |
|---|---|---|---|
| Global | `~/.claude/memory/MEMORY.md` | All sessions | User preferences, usage patterns, cross-project notes |
| Project | `<project>/MEMORY.md` | Per-project | Research threads, decisions, notation, proof sketches, references, open questions |

### How it works

**Session start:** Claude reads global memory, plus the project memory if working inside `~/claude-projects/<project>/`.

**Session end (or major milestone):** Claude updates the relevant memory files with compressed entries (1-3 sentences each). Updates happen at most twice per session per file, using targeted edits — not full rewrites.

**Trivial sessions** (quick question, small fix): memory updates are skipped entirely.

### Auto-setup for new projects

When Claude is first run inside a `~/claude-projects/` subdirectory that has no `MEMORY.md`, it automatically:
1. Creates `MEMORY.md` in the project root with sections adapted to the project type (research vs code)
2. Creates a project `CLAUDE.md` in `~/.claude/projects/<shadow-key>/` pointing to the memory file
3. Informs the user

No manual instruction needed — just `cd ~/claude-projects/new-project && claude`.

### What gets recorded

- Research thread status changes, key decisions with rationale
- Notation conventions, proof sketches (claim + approach + status, not full proofs)
- Paper references with 1-line relevance notes, code artifact locations
- Open questions and conjectures

### What doesn't get recorded

- Routine edits, full proof text, verbose explanations
- Memory is a compressed index, not a narrative

### Cost impact

Negligible. Reading is one small file read (~free). Writing is ≤2 small edits per file per session. No subagents are spawned for memory updates.

## Auto-Documentation

This file (`~/claude-projects/docs/claude-setup.md`) is automatically kept in sync with the actual environment. When Claude adds, removes, or changes any of the following, it updates the relevant section of this doc in the same session:

- Workflows or automation (memory system, EOD agents, etc.)
- Skills or slash commands
- Subagents
- Settings (permissions, hooks, model defaults)
- Directory structure under `~/.claude/` or `~/claude-projects/`
- MCP server configuration

Updates are targeted edits, not full rewrites, and count toward the session write budget. Trivial changes (typos, minor reformatting) don't trigger doc updates.

## Cost Management

### Daily budget guidance (~$22/day to stay within $480/month)

| Activity | Model | Estimated Daily Cost |
|---|---|---|
| Interactive math/coding (2-3 hrs) | Opus | $8-12 |
| Paper reading (3-5 papers) | Sonnet | $2-5 |
| EOD automation | Sonnet/Haiku | $1-3 |
| LaTeX review | Sonnet | $1-2 |
| Codebase exploration | Haiku | $0.50-1 |
| **Total** | | **$12.50-23** |

### Cost tips
- `/clear` between unrelated tasks (stale context is billed on every message)
- Use Plan Mode (Shift+Tab) before complex implementations
- Skills load on-demand; CLAUDE.md loads always — keep CLAUDE.md lean
- For long outputs, ask for structured/tabular format over prose
- Check spending with `/cost` in-session

## Sources

This setup draws from:
- [Mitchell Hashimoto — My AI Adoption Journey](https://mitchellh.com/writing/my-ai-adoption-journey) — end-of-day agents, harness engineering, notification discipline
- [matsengrp/plugins](https://github.com/matsengrp/plugins) (MIT) — scientific-tex-editor, journal-submission-checker, pdf-question-answerer agents
- [pedrohcgs/claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow) (MIT) — compile-latex, proofread, lit-review, review-paper, validate-bib, research-ideation skills
- [Spotify Engineering — Context Engineering for Background Agents](https://engineering.atspotify.com/2025/11/context-engineering-background-coding-agents-part-2) — one change per prompt, focused tasks
- [Claude Code official docs](https://code.claude.com/docs/en/costs) — cost management, subagents, headless mode
- [Simon Willison](https://simonwillison.net/tags/claude-code/) — skills over MCP for cost efficiency
