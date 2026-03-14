---
name: lit-review
description: Structured literature search and synthesis with citation extraction and gap identification. Searches eprint, arxiv, and the web.
disable-model-invocation: true
argument-hint: "<topic, paper title, or research question>"
allowed-tools: ["Read", "Grep", "Glob", "Write", "WebSearch", "WebFetch"]
---

# Literature Review

Conduct a structured literature search and synthesis on a cryptography or mathematics topic.

**Input:** `$ARGUMENTS` — a topic, paper title, research question, or construction to investigate.

## Steps

1. **Parse the topic** from `$ARGUMENTS`.

2. **Search for related work:**
   - Use `WebSearch` to find papers on eprint.iacr.org, arxiv.org, and Google Scholar
   - Use `WebFetch` to access paper abstracts and metadata
   - Check any existing `.bib` files in the current directory for already-known papers

3. **Organize findings** into categories:
   - **Constructions** — schemes, protocols, proof systems
   - **Theoretical foundations** — hardness assumptions, impossibility results, lower bounds
   - **Efficiency improvements** — concrete optimizations, implementation techniques
   - **Open problems** — unresolved questions, conjectures

4. **Identify gaps and opportunities:**
   - What questions remain unanswered?
   - Where do results conflict or leave room for improvement?
   - What assumptions could be weakened?

5. **Extract citations** in BibTeX format for all papers discussed.

6. **Save the report** to `lit_review_[sanitized_topic].md` in the current directory.

## Output Format

```markdown
# Literature Review: [Topic]

**Date:** [YYYY-MM-DD]
**Query:** [Original query]

## Summary
[2-3 paragraph overview]

## Key Papers

### [Author (Year)] — [Short Title]
- **Main contribution:** [1-2 sentences]
- **Assumption:** [Hardness assumption]
- **Proof technique:** [Game-based / simulation / UC / etc.]
- **Efficiency:** [Proof size, rounds, computation]
- **Relevance:** [Connection to user's research]
- **Link:** [eprint/arxiv URL]

## Comparison Table

| Construction | Assumption | Proof Size | Rounds | Proof Technique |
|---|---|---|---|---|

## Gaps and Opportunities
1. [Gap 1]
2. [Gap 2]

## BibTeX Entries
```

## Important
- **Do NOT fabricate citations.** If unsure about a paper's details, flag it.
- **Prioritize recent work** (last 5-10 years) unless seminal papers are older.
- **Note preprints vs published papers.**
- **Include eprint/arxiv links** wherever possible.

Adapted from pedrohcgs/claude-code-my-workflow (MIT license).
