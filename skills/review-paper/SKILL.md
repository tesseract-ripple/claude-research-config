---
name: review-paper
description: Comprehensive manuscript review covering technical correctness, proof validity, security analysis, and presentation quality. Simulates a top-venue referee report.
disable-model-invocation: true
argument-hint: "<path to .tex or .pdf file>"
allowed-tools: ["Read", "Grep", "Glob", "Write", "Task"]
---

# Manuscript Review

Produce a thorough, constructive review of an academic manuscript in cryptography or mathematics — the kind of report a top-venue (CRYPTO, EUROCRYPT, CCS) referee would write.

**Input:** `$ARGUMENTS` — path to a paper (.tex or .pdf).

## Steps

1. **Read the full paper** end-to-end. For large PDFs, read in chunks (5 pages at a time).

2. **Evaluate across 6 dimensions** (see below).

3. **Generate 3-5 "referee objections"** — the tough questions a program committee member would ask.

4. **Save the review** to `review_[sanitized_name].md` in the current directory.

## Review Dimensions

### 1. Technical Correctness
- Are the proofs correct? Check each step for logical gaps.
- Are reductions tight? Is the advantage loss acceptable?
- Are the hardness assumptions standard and correctly stated?
- Do the security definitions match the claimed properties?

### 2. Novelty & Contribution
- Is the contribution clearly stated?
- How does it improve over prior work (asymptotically, concretely, in assumptions)?
- Is the contribution primarily theoretical or does it have practical implications?

### 3. Security Model
- Is the threat model clearly defined?
- Are there gaps between the model and realistic deployment?
- Are the security definitions appropriate (IND-CPA vs IND-CCA, simulation vs game-based)?

### 4. Efficiency Analysis
- Are efficiency claims supported by concrete analysis or benchmarks?
- How does efficiency compare to prior work?
- Are the relevant metrics reported (proof size, verification time, prover time, communication)?

### 5. Literature Positioning
- Are key related works cited?
- Is the comparison to prior work accurate and fair?
- Are there missing references a referee would flag?

### 6. Presentation Quality
- Is the paper clearly written?
- Is notation consistent throughout?
- Are definitions, theorems, and proofs well-structured?
- Are figures and tables informative?

## Output Format

```markdown
# Review: [Paper Title]

**Date:** [YYYY-MM-DD]

## Summary Assessment
**Recommendation:** [Strong Accept / Accept / Borderline / Reject]
[2-3 paragraph summary]

## Strengths
1. [Strength]

## Major Concerns
### MC1: [Title]
- **Dimension:** [Correctness / Novelty / Security / Efficiency / Literature / Presentation]
- **Issue:** [Specific description]
- **Suggestion:** [How to address]

## Minor Concerns
### mc1: [Title]
- **Issue / Suggestion**

## Referee Objections
### RO1: [Question]
**Why it matters:** [Why this could be fatal]
**How to address:** [Suggested response]

## Ratings
| Dimension | Rating (1-5) |
|---|---|
| Technical Correctness | |
| Novelty | |
| Security Model | |
| Efficiency | |
| Literature | |
| Presentation | |
```

Adapted from pedrohcgs/claude-code-my-workflow (MIT license).
