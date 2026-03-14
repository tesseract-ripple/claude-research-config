---
name: validate-bib
description: Cross-reference all citations in .tex files against bibliography entries. Find missing entries, unused references, and quality issues.
disable-model-invocation: true
argument-hint: "[path to .bib file, or omit to auto-detect]"
allowed-tools: ["Read", "Grep", "Glob"]
---

# Validate Bibliography

Cross-reference all citations in LaTeX files against bibliography entries.

## Steps

1. **Find the bibliography file:**
   - If `$ARGUMENTS` provided, use that
   - Otherwise, look for `*.bib` files in the current directory

2. **Read the bibliography file** and extract all citation keys.

3. **Scan all .tex files** for citation commands:
   - `\cite{`, `\citet{`, `\citep{`, `\citeauthor{`, `\citeyear{`, `\citenum{`
   - Handle multi-cite: `\cite{key1,key2,key3}`
   - Extract all unique citation keys used

4. **Cross-reference:**
   - **Missing entries:** Citations used in .tex but NOT in .bib (CRITICAL)
   - **Unused entries:** Entries in .bib not cited anywhere (informational)
   - **Potential typos:** Similar-but-not-matching keys (Levenshtein distance)

5. **Check entry quality** for each bib entry:
   - Required fields present (author, title, year, journal/booktitle)
   - Year is reasonable
   - ePrint/arXiv entries have the `eprint` field
   - No duplicate keys
   - Author field properly formatted

6. **Report findings** grouped by severity.

Adapted from pedrohcgs/claude-code-my-workflow (MIT license).
