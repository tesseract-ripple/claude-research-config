---
name: research-ideation
description: Generate structured research questions, conjectures, and proof strategies from a topic or open problem in cryptography/mathematics.
disable-model-invocation: true
argument-hint: "<topic, open problem, or construction to improve>"
allowed-tools: ["Read", "Grep", "Glob", "Write", "WebSearch", "WebFetch"]
---

# Research Ideation

Generate structured research questions, conjectures, and proof strategies from a cryptography or mathematics topic.

**Input:** `$ARGUMENTS` — a topic (e.g., "range proofs from lattices"), an open problem (e.g., "transparent setup for Bulletproofs"), or a construction to improve (e.g., "reduce Pedersen commitment opening proof size").

## Steps

1. **Understand the input.** Read `$ARGUMENTS` and any referenced files in the current directory.

2. **Search for context** using WebSearch on eprint.iacr.org and arxiv.org to understand the current state of the art.

3. **Generate 3-5 research directions** ordered by ambition:
   - **Incremental:** Small improvement to existing construction (e.g., reduce proof size by constant factor)
   - **Moderate:** New construction or technique within existing paradigm (e.g., new commitment scheme from different assumption)
   - **Ambitious:** Paradigm shift or resolution of open problem (e.g., achieve X without trusted setup)

4. **For each direction, develop:**
   - **Conjecture/Goal:** A precise statement of what you'd want to prove or build
   - **Approach:** Proof strategy or construction idea
   - **Key obstacles:** What makes this hard? Where would the proof get stuck?
   - **Required assumptions:** What hardness assumptions are needed?
   - **Potential tools:** Existing techniques or lemmas that might help
   - **Related work:** 2-3 papers using similar approaches
   - **Feasibility assessment:** How likely is this to work?

5. **Save the output** to `research_ideation_[sanitized_topic].md` in the current directory.

## Output Format

```markdown
# Research Ideation: [Topic]

**Date:** [YYYY-MM-DD]
**Input:** [Original input]

## State of the Art
[1-2 paragraphs summarizing current best results]

## Research Directions

### RD1: [Title] (Feasibility: High/Medium/Low)

**Goal:** [Precise statement]
**Approach:** [Proof strategy or construction sketch]
**Key obstacles:**
1. [Obstacle and potential mitigation]
2. [Obstacle and potential mitigation]
**Assumptions:** [Required hardness assumptions]
**Related work:** [Author (Year)], [Author (Year)]

## Ranking
| Direction | Feasibility | Impact | Novelty |
|---|---|---|---|

## Suggested Next Steps
1. [Most promising immediate action]
2. [Paper to read carefully]
3. [Computation to try]
```

## Principles
- **Be creative but rigorous.** Every suggestion must be mathematically plausible.
- **Think like a reviewer.** Immediately identify why a proof strategy might fail.
- **Do NOT fabricate references.**
- **Flag connections** to known open problems or conjectures.

Adapted from pedrohcgs/claude-code-my-workflow (MIT license).
