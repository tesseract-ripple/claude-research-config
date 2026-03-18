# LaTeX Crypto/Math Setup

**Date:** 2026-02-25 (Cowork session export)

This documents the self-contained LaTeX style system for crypto/math research papers.
Source files live in `~/.config/latex-export/`.

## Files

| File | Purpose |
|---|---|
| `~/.config/latex-export/crypto-math.sty` | Master style sheet — all packages and macros |
| `~/.config/latex-export/template.tex` | Full paper template using the style sheet |
| `~/.config/latex-export/latex.json` | VSCode user snippets |
| `~/.config/latex-export/latex-setup.md` | Detailed installation guide (original) |

## Installation (done 2026-02-25)

### 1. TEXMF — `crypto-math.sty` on TeX's search path

Note: on this machine `TEXMFHOME` is `~/Library/texmf` (not `~/texmf`).

```bash
mkdir -p ~/Library/texmf/tex/latex/local
cp ~/.config/latex-export/crypto-math.sty ~/Library/texmf/tex/latex/local/
mktexlsr ~/Library/texmf
kpsewhich crypto-math.sty   # should print ~/Library/texmf/…/crypto-math.sty
```

### 2. VSCode snippets

```bash
cp ~/.config/latex-export/latex.json \
   "$HOME/Library/Application Support/Code/User/snippets/latex.json"
```

### 3. ChkTeX linting

ChkTeX is at `/Library/TeX/texbin/chktex`. VS Code can't find it by default because
`/Library/TeX/texbin` isn't in the PATH VS Code inherits. Fixed via:

```json
"latex-workshop.linting.chktex.exec.path": "/Library/TeX/texbin/chktex"
```

### 4. VSCode extensions installed

| Extension | ID | Purpose |
|---|---|---|
| LaTeX Workshop | `james-yu.latex-workshop` | Build, PDF preview, intellisense, SyncTeX, formatter |
| LTeX | `valentjn.vscode-ltex` | Grammar/spell check, LaTeX-aware |
| LaTeX (mathematic) | `mathematic.vscode-latex` | Syntax highlighting, symbol autocomplete |

### 5. `~/.latexmkrc`

Created at `~/.latexmkrc`: pdflatex mode, biber, default file `main.tex`,
cleans `bbl bcf run.xml synctex.gz`. Commands use full paths
(`/Library/TeX/texbin/pdflatex`, `/Library/TeX/texbin/biber`) so that
latexmk works in environments without `/Library/TeX/texbin` on `$PATH`
(e.g., VS Code LaTeX Workshop).

### 6. Word wrap at 100 columns (format on save)

`latexindent` (ships with MacTeX) handles hard-wrapping. Required missing Perl
modules installed via brew Perl (`File::HomeDir`, `YAML::Tiny`).

Config file at `~/.config/latexindent.yaml` — wraps prose at 100 cols,
does not touch math environments or command arguments.

VSCode `settings.json` additions (all scoped to `[latex]` where appropriate):
- `latex-workshop.formatting.latex: "latexindent"`
- `latex-workshop.latexindent.args`: passes `-l ~/.config/latexindent.yaml -m`
- `editor.formatOnSave: true`
- `editor.wordWrap: "off"` (physical wrap via formatter, not soft-wrap)
- `editor.rulers: [100]` (visual guide)

## What crypto-math.sty does

The style sheet is structured in 16 numbered sections. Load order follows a strict
dependency chain: fonts → math → floats → theorems → layout → bibliography → hyperref → cleveref.
Nothing should be loaded after `cleveref`.

### Packages included

**Fonts & typography:** `lmodern`, `microtype` (protrusion + expansion + tracking + kerning).

**Mathematics:** `amsmath`, `mathtools`, `amssymb`, `amsfonts`, `stmaryrd`
(`\llbracket`, `\rrbracket`), `mathrsfs` (`\mathscr`), `bm` (bold math),
`isomath` (ISO vector/matrix notation), `complexity` (`\NP`, `\P`, `\BPP`, …).

**Theorems:** `thmtools` + `thm-restate`. All environments (Theorem, Lemma,
Proposition, Corollary, Claim, Conjecture, Definition, Example, Construction,
Protocol, Remark, Note) share a single counter anchored to the section number.
Unnumbered starred variants provided for all main types. QED symbol is `■`.

**Pseudocode:** `algorithm` + `algpseudocode` (algorithmicx). `cryptocode` is
commented out as an alternative for IACR-style game-based proofs — swap them
if most work targets IACR venues.

**Figures/tables:** `graphicx`, `xcolor`, `booktabs`, `subcaption`, `tikz`,
`pgfplots` (compat 1.18) with common tikzlibraries.

**Bibliography:** `biblatex` + `biber`, `alphabetic` style ([ABC+20]). `natbib`
is commented out for easy switching if a venue requires classic BibTeX.

**Cross-references:** `hyperref` (colored links: blue internal, green citations,
cyan URLs) then `cleveref` (capitalize, no abbreviation). All theorem-like
environments have custom `\crefname` entries.

**Editing aids:** `todonotes`, `soul` (`\hl`, `\sout`), `comment`. In `anonymous`
mode, `\todo` and `\missingfigure` are silently suppressed.

### Package options

| Option | Effect |
|---|---|
| *(none)* | Default — full microtype, hyperref final |
| `draft` | microtype draft mode, hyperref draft (no links) |
| `anonymous` | Suppresses todo notes (for double-blind submission) |

### Global overrides

- `\phi` → `\varphi` everywhere (document this when sharing the sty with collaborators)
- `\emptyset` → `\varnothing` everywhere

### Macro categories

**Number systems:** `\N \Z \Q \R \C \F`, `\GF{q}`, `\Zmod{n}`, `\Zstar{n}`

**Paired delimiters (auto-scaling):** `\abs`, `\norm`, `\floor`, `\ceil`,
`\angbr` (inner product), `\sembrack` (semantic brackets `⟦·⟧`)

**Probability:** `\E[subscript]{expr}`, `\Pr[subscript]{event}`, `\getsu`
(←$), `\sdist{D_0}{D_1}`, `\kldiv{P}{Q}`, `\entropy`, `\renyi{\alpha}{X}`

**Cryptography:** `\secpar` (λ), `\secp` (1^λ), `\negl`, `\PPT`,
`\Adv{game}{scheme}`, `\Exp{game}{scheme}`, `\Win`, `\Succ`, `\Bad`

**Adversaries/oracles:** `\A` (adversary), `\B` (reduction), `\Sim` (simulator
`\mathcal{S}`), `\D` (distinguisher/distribution), `\RO` (random oracle)

**Hardness assumptions:** `\DLog`, `\CDH`, `\DDH`, `\RSA`, `\LWE`, `\RLWE`,
`\SIS`, `\RSIS`, `\SVP`, `\CVP`, `\ISIS`

**Scheme algorithms:** `\Setup`, `\KeyGen`, `\Enc`, `\Dec`, `\Sign`, `\Verify`,
`\Hash`, `\Eval`, `\Commit`, `\Open`, `\Prove`, `\Extract`

**Keys/params:** `\pk`, `\sk`, `\pp`, `\msk`, `\mpk`, `\vk`, `\ek`, `\td`, `\crs`

**Groups/lattices:** `\GG` (generic group), `\GT` (target group), `\Zq`, `\Zp`,
`\LL` / `\lat` (lattice), `\ip{x,y}` (inner product), `\smoothp` (smoothing parameter)

**Asymptotic:** `\bigO{·}`, `\bigOt{·}` (Õ), `\bigTheta{·}`, `\bigOmega{·}`, `\poly`

### VSCode snippets

Type the prefix in any `.tex` file, then Tab.

| Prefix | Expands to |
|---|---|
| `cryptopaper` | Full document skeleton with all sections |
| `thm` | `\begin{theorem}[Name] \label{thm:…}` |
| `lem` | Lemma environment |
| `defn` | Definition environment |
| `prf` | Proof block |
| `rethm` | Restatable theorem (for stating in intro, proving later) |
| `alg` | Algorithm (algorithmicx) skeleton |
| `ali` | `align` environment |
| `adv` | `\Adv{game}{scheme}(\A) \le …` |
| `lweassum` | Standard LWE assumption sentence |
| `sec` | `\section{Title} \label{sec:…}` |
| `tikzfig` | TikZ figure skeleton |

## Known issues fixed during build

Three bugs were caught and fixed before delivery (all present in current sty):

1. `\Sim` defined twice — removed the duplicate in the "Adversaries" block.
2. `\Span` had two `\DeclareMathOperator` calls — `\DeclareMathOperator` is not
   idempotent; removed the second call.
3. `\if@cmbdraft` inside `\RequirePackage[…]{hyperref}` — LaTeX does not expand
   conditionals in package option lists. Fixed using `\PassOptionsToPackage`
   before the `\RequirePackage`.

## latexdiff workflow (added 2026-03-17)

After editing any `.tex` file in a git repo, Claude generates a diff PDF for visual review:
1. Baseline captured from `git show HEAD:<file>.tex` before edits begin
2. `latexdiff` + `pdflatex` run in `/tmp/` after edits complete
3. Diff PDF copied to project directory (not committed — gitignored via `*-diff.{tex,pdf}`)

No separate baseline files are maintained. Instructions live in `~/.claude/CLAUDE.md` under "Working With LaTeX > Diff PDF generation".

## Compilation policies

- **Zero warnings.** All LaTeX documents should compile with zero warnings. After compiling, check for and fix all warnings before considering the build clean.
- **hyperref `\texorpdfstring`.** Any math (`$...$`) in `\section`, `\subsection`, or other sectioning commands must be wrapped in `\texorpdfstring{<latex>}{<plaintext>}` to avoid "Token not allowed in a PDF string" warnings. This includes inline math fragments like `1-to-$N$`, not just standalone math expressions.
- **Float specifiers.** Use `[ht]` or `[htbp]` rather than bare `[h]` to avoid "float specifier changed" warnings.

## Open questions / future work

- Decide `\E` convention: current `\E[sub]{expr}` uses `\mathbb{E}` via `\Expect`;
  some authors prefer a plain `\mathbf{E}` or `\mathbb{E}` without the operator form.
  Pick one and document it in the sty header.
- Consider `tcolorbox`-based colored theorem boxes (common in recent CRYPTO/TCC papers).
- Run `/compile-latex` against `template.tex` to verify the full toolchain end-to-end.
- Run `/validate-bib` once a `refs.bib` is in place.
