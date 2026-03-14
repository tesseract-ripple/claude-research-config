---
name: compile-latex
description: Compile a LaTeX document with full citation resolution (pdflatex + bibtex, 3 passes). Reports warnings and errors.
disable-model-invocation: true
argument-hint: "<path to .tex file>"
allowed-tools: ["Read", "Bash", "Glob"]
---

# Compile LaTeX Document

Compile a LaTeX document with full citation and cross-reference resolution.

## Steps

1. **Identify the file** from `$ARGUMENTS`. If just a filename, search the current directory and subdirectories.

2. **Compile with 3-pass sequence:**

```bash
pdflatex -interaction=nonstopmode "$ARGUMENTS"
bibtex "$(basename "$ARGUMENTS" .tex)"
pdflatex -interaction=nonstopmode "$ARGUMENTS"
pdflatex -interaction=nonstopmode "$ARGUMENTS"
```

If a `Makefile` or `latexmk` config exists in the same directory, prefer that instead.

3. **Check for warnings:**
   - `Overfull \\hbox` warnings
   - `undefined citations` or `Label(s) may have changed`
   - Missing references
   - Font warnings

4. **Report results:**
   - Compilation success/failure
   - Number and location of overfull hbox warnings
   - Any undefined citations or references
   - PDF page count (via `pdfinfo` if available)

5. **Open the PDF** for visual verification:
   ```bash
   open "$(basename "$ARGUMENTS" .tex).pdf"
   ```

Adapted from pedrohcgs/claude-code-my-workflow (MIT license).
