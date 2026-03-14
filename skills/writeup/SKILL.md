---
name: writeup
description: Draft or refine a LaTeX section for a research paper, note, or proof writeup.
argument-hint: "<section description or content to refine>"
---

The user wants help writing or refining LaTeX for a research document. Follow this process:

1. **Understand context.** Read any existing .tex files in the current directory to match the document's style, notation, and structure.
2. **Draft.** Write the LaTeX content. Follow these conventions unless the existing document uses something different:
   - `\mathbb{F}_p`, `\mathbb{Z}_n` for fields/rings
   - `\mathcal{A}`, `\mathcal{S}` for adversaries/simulators
   - `\lambda` for security parameter
   - `\mathsf{Com}`, `\mathsf{Open}`, `\mathsf{Verify}` for algorithm names
   - `\stackrel{?}{=}` for verification checks
   - Use `align*` for multi-line equations
3. **Compile check.** If the user has a main .tex file, suggest a compile command but don't run it unless asked.
4. **Review.** Check for: notation consistency with the rest of the document, mathematical correctness, clear exposition.

Request: $ARGUMENTS
