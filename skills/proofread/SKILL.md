---
name: proofread
description: Proofread a LaTeX document for grammar, typos, notation consistency, and academic writing quality. Produces a report without editing files.
disable-model-invocation: true
argument-hint: "<filename or 'all' for all .tex files in current dir>"
allowed-tools: ["Read", "Grep", "Glob", "Write", "Task"]
---

# Proofread LaTeX Files

Run the proofreading protocol on LaTeX files. Produces a report of all issues found WITHOUT editing any source files.

## Steps

1. **Identify files to review:**
   - If `$ARGUMENTS` is a specific filename: review that file only
   - If `$ARGUMENTS` is "all": review all `.tex` files in the current directory

2. **For each file, check for:**

   **GRAMMAR:** Subject-verb agreement, articles (a/an/the), tense consistency (present for established results, past for "we showed")
   **TYPOS:** Misspellings, duplicated words, search-and-replace artifacts
   **NOTATION:** Consistent use of $\mathbb{F}_p$, $\mathcal{A}$, $\lambda$; variables introduced before use; quantifiers explicit
   **LATEX:** Missing `~` before `\cite`/`\ref`, `\left`/`\right` mismatches, mismatched environments
   **ACADEMIC QUALITY:** Informal language, vague claims ("it is clear that..."), missing words

3. **Produce a report** listing every finding with:
   - Line number
   - Current text
   - Proposed fix
   - Category and severity

4. **IMPORTANT: Do NOT edit any source files.** Only produce the report.

5. **Present summary** to the user:
   - Total issues per file
   - Breakdown by category
   - Most critical issues highlighted

Adapted from pedrohcgs/claude-code-my-workflow (MIT license).
