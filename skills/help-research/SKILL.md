---
name: help-research
description: Show cheat sheet of all custom slash commands and subagents for the research environment.
user-invocable: true
disable-model-invocation: true
---

Print this cheat sheet exactly as-is. Do not run any tools. Do not add commentary.

```
╔══════════════════════════════════════════════════════════════════════╗
║                    RESEARCH ENVIRONMENT CHEAT SHEET                 ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  MATH & CRYPTO                                                       ║
║  ─────────────                                                       ║
║  /prove <claim>              Construct or verify a proof             ║
║  /verify <expr>              Computationally check an identity       ║
║  /survey <topic>             Literature survey with comparison table  ║
║  /research-ideation <topic>  Generate research directions            ║
║                                                                      ║
║  PAPER WRITING                                                       ║
║  ─────────────                                                       ║
║  /writeup <section>          Draft LaTeX in your document's style    ║
║  /compile-latex <file.tex>   Compile (pdflatex+bibtex, 3 passes)    ║
║  /proofread <file|all>       Grammar & notation report (no edits)   ║
║  /validate-bib [file.bib]    Cross-check citations vs bibliography  ║
║                                                                      ║
║  PAPER READING                                                       ║
║  ─────────────                                                       ║
║  /lit-review <topic>         Structured search + BibTeX extraction   ║
║  /review-paper <file>        Referee-style review (CRYPTO/CCS)      ║
║                                                                      ║
║  META                                                                ║
║  ────                                                                ║
║  /help-research              This cheat sheet                        ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  SUBAGENTS (auto-invoked or via Task tool)                           ║
║  ─────────────────────────────────────────                           ║
║  paper-reader          [sonnet]  Summarize crypto/math papers        ║
║  pdf-question-answerer [sonnet]  Answer questions about a PDF        ║
║  code-explorer         [haiku]   Navigate C++/Rust codebases         ║
║  code-reviewer         [sonnet]  Review diffs for correctness        ║
║  tex-checker           [sonnet]  LaTeX grammar & notation            ║
║  scientific-tex-editor [sonnet]  Deep scientific prose editing       ║
║  journal-submission-checker [haiku] Pre-submission quality gate      ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  END-OF-DAY WORKFLOW                                                 ║
║  ───────────────────                                                 ║
║  ~/.claude/scripts/eod-agents.sh [task...]                           ║
║                                                                      ║
║  Tasks:  triage   — issue/PR triage for repos in ~/claude-projects   ║
║          papers   — summarize PDFs in ~/claude-projects/papers-inbox ║
║          review   — review last 24h of commits                       ║
║          explore  — run prompts from ~/claude-projects/explore-prompts.txt ║
║                                                                      ║
║  Reports go to ~/claude-projects/eod-reports/YYYY-MM-DD/             ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  COST TIPS                                                           ║
║  ─────────                                                           ║
║  /cost             Check current session spend                       ║
║  /clear            Clear context between unrelated tasks             ║
║  /model sonnet     Switch to sonnet for cheaper tasks                ║
║  Shift+Tab         Plan Mode — explore before implementing           ║
║                                                                      ║
║  Docs: ~/claude-projects/docs/claude-setup.md                        ║
╚══════════════════════════════════════════════════════════════════════╝
```
