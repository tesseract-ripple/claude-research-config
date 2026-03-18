# Claude Code Research Environment Setup

**Last updated:** 2026-03-17
**Account:** Enterprise plan, $480 spending cap, Opus 4.6 default model

## Architecture

`~/claude-projects/` is a **real local directory** (not on Google Drive). Document files are synced to GDrive for cross-device reading via a background rsync job (see Background Jobs below).

Configuration source of truth is `~/claude-projects/claude-research-config/` (git repo, mirrored to GitHub). Key files in `~/.claude/` are **symlinks** pointing there:
- `CLAUDE.md` → `claude-research-config/claude.md`
- `settings.json` → `claude-research-config/settings.json`
- `agents/`, `skills/`, `scripts/` → `claude-research-config/`
- `keybindings.json`, `usage-config.json` → `claude-research-config/`

Additional symlinks from `~/.config/` (tmux, kitty, fish, git, latex, swiftbar) and `~/.latexmkrc`, `~/.gitconfig` also point into `claude-research-config/`.

```
~/.claude/                           # All config lives here (some symlinked)
├── CLAUDE.md -> claude-research-config  # Global agent instructions
├── memory/
│   └── MEMORY.md                    # Global memory (auto-maintained)
├── settings.json -> claude-research-config  # Model, permissions, hooks
├── hooks/                           # Hook scripts (called by settings.json)
│   ├── memory-read-reminder.sh      # SessionStart — read memory files
│   ├── memory-update-reminder.sh    # Stop — update memory files
│   ├── latexdiff-baseline-reminder.sh # PreToolUse — capture .tex baseline
│   ├── latexdiff-stop-check.sh      # Stop — block if .tex diffs missing
│   ├── docs-staleness-check.sh      # SessionStart — compare docs vs actual filesystem
│   ├── docs-semantic-check-gate.sh  # Stop — semantic audit if config/docs were edited
│   ├── docs-update-reminder.sh      # PostToolUse (Write|Edit) — docs trigger table
│   ├── docs-bash-reminder.sh        # PostToolUse (Bash) — structural changes in monitored paths
│   ├── subagent-cost-check.sh       # SubagentStart — opus cost warning
│   └── memory-periodic-reminder.sh  # UserPromptSubmit — 30min memory flush
│   └── sentinels/                   # Session-scoped sentinel files (auto-created/removed)
│       ├── last-memory-write        # Timestamp for 30-min memory flush timer
│       ├── docs-edited-this-session # Gates Stop audit (session IDs, one per line)
│       ├── docs-reminder-shown      # Once-per-session docs reminder (session IDs, one per line)
│       └── latexdiff-stop-checked   # Once-per-session latexdiff block
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
│   ├── research-ideation/SKILL.md   # /research-ideation — idea generation
│   ├── git/SKILL.md                 # /git — git best practices
│   ├── git-worktrees/SKILL.md       # /git-worktrees — isolated worktrees
│   └── context7/SKILL.md            # /context7 — library docs lookup
├── projects/                        # Per-project CLAUDE.md (shadow dirs, auto-created)
└── scripts/                         # (symlink → claude-research-config/scripts/)
    ├── eod-agents.sh                # End-of-day batch runner
    ├── sync-config.sh               # Auto-commit+push config to GitHub (launchd, 10min)
    └── sync-docs-to-gdrive.sh       # rclone documents to GDrive (launchd, 10min)

~/claude-projects/                   # Working directory for Claude-visible repos
├── claude-research-config/          # Config source of truth (symlinked into ~/.claude/)
├── confidential-transactions/       # CT research (LaTeX, PDFs, bib)
│   └── MEMORY.md                    # Project memory (auto-maintained)
├── mpt-crypto-clean/                # MPT crypto library (C, secp256k1)
│   └── MEMORY.md                    # Project memory (auto-maintained)
├── mpt-crypto-papers/               # MPT-related papers
├── canton/                          # Canton project
├── ripple-claude-marketplace/       # GitLab: ripple/ai/claude-marketplace
├── rippled/                         # xrplf/rippled checkout
├── claude-usage/                    # Usage tracking widget
├── papers-inbox/                    # Drop PDFs here for EOD processing
├── eod-reports/                     # Daily reports from eod-agents.sh
├── explore-prompts.txt              # Research questions for EOD exploration
├── papers -> ~/Documents/papers     # Symlink to papers library
├── zotero -> ~/Zotero               # Symlink to Zotero database
└── docs/                            # This documentation (auto-updated)
```

## Background Jobs (launchd)

Two launchd agents run every 10 minutes. Plists in `~/Library/LaunchAgents/`. Both have lock files and exponential backoff on failure.

| Job | Plist | Script | Purpose |
|-----|-------|--------|---------|
| `com.claude.config-sync` | `com.claude.config-sync.plist` | `claude-research-config/scripts/sync-config.sh` | Auto-commit and push config changes to GitHub. Skips if no uncommitted changes (`git diff --quiet`). |
| `com.claude.docs-gdrive-sync` | `com.claude.docs-gdrive-sync.plist` | `claude-research-config/scripts/sync-docs-to-gdrive.sh` | rclone document files (pdf, tex, bib, md, txt, png, jpg, svg) to `gdrive:claude-projects-docs/` for cross-device reading. Follows symlinks (`-L`), skips `.git/` and non-document files. Cheap local `find -newer` check skips rclone if nothing changed since last sync. |

Logs at `/tmp/claude-config-sync.log` and `/tmp/claude-docs-gdrive-sync.log`.

**Why `~/claude-projects/` is local, not on GDrive:** GDrive's File Provider volume is inaccessible to background launchd agents (macOS TCC restrictions), and GDrive's "My Mac" backup can't handle symlinks. Keeping the directory local avoids both issues. Document files are synced via rclone to a separate GDrive folder instead.

## MCP Servers

Configured in `~/.claude/.mcp.json`.

| Server | Transport | Purpose |
|---|---|---|
| `context7` | stdio (`npx @upstash/context7-mcp`) | Live library/framework documentation lookup. Pairs with `/context7` skill. |
| `atlassian` | SSE (`https://mcp.atlassian.com/v1/sse`) | Jira and Confluence integration (OAuth, first use prompts auth). |

## Settings

### Model
Default: `opus`. Use `/model sonnet` or `/model haiku` in-session for cheaper tasks.

### Attribution
Commit and PR attribution suppressed (empty strings). No "Co-Authored-By" lines or AI mentions in commits/PRs, per Ripple convention.

### Permissions

**Auto-allowed (no prompt):**
- Python, SageMath, LaTeX, latexdiff, C/C++ compilation
- Git read-only operations (log, diff, status, show) — bare and via `git -C`
- Git local write operations (add, commit, branch, stash) — bare and via `git -C`
- Edit/Write for docs (`~/claude-projects/docs/*`) and memory (`*MEMORY.md`) files
- File reading, search, web search
- `touch`, `cp * /tmp/*` (for hook sentinels and latexdiff workflows)

**Auto-denied:**
- `rm -rf`, `git push`, `git checkout --`, `git reset --hard` (bare and `git -C` forms)
- Reading `.env` files or `secrets/` directories

**Prompted (requires confirmation):**
- File writes/edits outside docs and memory paths
- Any git operation not listed above

### Hooks

All hook logic lives in `~/.claude/hooks/*.sh` scripts (not inline JSON) for maintainability.

- **SessionStart**: (1) Reminds Claude to read global memory (`~/.claude/memory/MEMORY.md`) and project memory (`<project>/MEMORY.md` if it exists, found by walking up from cwd); (2) runs docs staleness check — compares `~/claude-projects/`, `~/.claude/hooks/`, `agents/`, `skills/`, `scripts/` against what `claude-setup.md` documents, and flags discrepancies (pure filesystem checks, zero LLM cost)
- **Notification**: macOS notification + sound when Claude needs input
- **PreToolUse (Edit)**: On first `.tex` file edit per session, reminds to capture `git show HEAD:` baseline for latexdiff. Silent for non-.tex files or if baseline already exists in `/tmp/`
- **PostToolUse (Write|Edit)**: On qualifying edits to monitored paths, appends the current `session_id` to the sentinel file (deduped). Reminder shown once per session. Edits to `docs/*` are excluded (audit output, not input). Session-ID-based sentinels allow concurrent sessions without cross-talk
- **PostToolUse (Bash)**: On structural commands (`mkdir`, `cp`, `mv`, `git clone`, `touch`) in monitored paths (`~/.claude/`, `~/claude-projects/{claude-research-config,docs,claude-usage}/`, `~/.config/{kitty,tmux}/`), appends the current `session_id` to the sentinel file (deduped). Reminder shown once per session. Commands targeting `docs/*` or `sentinels/*` are excluded
- **UserPromptSubmit**: Every 30 minutes of active session, reminds to flush memory writes so concurrent sessions in the same directory see updates sooner. Uses sentinel file `~/.claude/hooks/sentinels/last-memory-write`; Claude touches it after writing memory to reset the timer
- **SubagentStart**: Warns when a subagent is spawned with opus model, showing the cost tier rules from CLAUDE.md
- **Stop**: (1) macOS notification; (2) blocks if `.tex` files have uncommitted changes without diff PDFs; (3) last-chance reminder to update memory files if session was non-trivial; (4) if the current `session_id` appears in the `docs-edited-this-session` sentinel, blocks stop with `decision:block` — Claude reads docs and corresponding configs, compares them, and fixes discrepancies before stopping. That session's line is removed before blocking; other sessions' entries are untouched. Empty sentinel files are cleaned up automatically. Loop prevention: audit edits only touch `docs/*`, which is excluded from re-setting the sentinel. Only fires when Claude stops naturally (not on Ctrl+C/exit)

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

## Skills / Slash Commands (14 total)

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

### Development
| Command | Purpose |
|---|---|
| `/git` | Git version control essentials and best practices |
| `/git-worktrees` | Create isolated git worktrees for feature work |
| `/context7` | Library documentation lookup with tokenization and reranking |

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
- [ripple/ai/claude-marketplace](https://gitlab.com/ripple/ai/claude-marketplace) (internal) — context7 skill+MCP, git/git-worktrees skills, Atlassian MCP config
