#!/bin/bash
# SubagentStart hook: warn when subagent uses opus
raw=$(jq -r '.model // empty')
case "$raw" in
  *opus*)
    msg="COST CHECK: This subagent is using opus — STOP and verify this is justified.

Opus is warranted for JUDGMENT/REASONING steps:
  - Evaluating a construction for correctness, imprecisions, or optimization opportunities
  - Proposing a recommendation based on mathematical or cryptographic analysis
  - Identifying subtle flaws, tradeoffs, or tightness issues in a proof/reduction
  - Reasoning about security properties of a specific construction

Opus is NOT warranted for INFORMATION steps:
  - Paper reading or summarization → use sonnet
  - Literature search or synthesis (combining information) → use sonnet
  - Document writing or LaTeX editing → use sonnet
  - Code generation or standard code review → use sonnet
  - Any task framed as 'tell me about X', 'write Y', 'find Z', or 'explain Q'

Key test: is this step producing a *judgment* that could be non-obviously wrong?
If yes → opus may be justified. If it's gathering, organizing, or writing → sonnet.
Do NOT use opus for a whole-workflow agent when only specific steps need it."
    jq -n --arg msg "$msg" '{systemMessage:$msg}'
    ;;
esac
