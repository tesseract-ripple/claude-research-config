#!/bin/bash
# SubagentStart hook: warn when subagent uses opus
raw=$(jq -r '.model // empty')
case "$raw" in
  *opus*)
    msg="COST CHECK: This subagent is using opus — STOP and verify this is justified.

Opus is ONLY warranted for:
  1. Verifying a specific proof or reduction for mathematical soundness
  2. Determining whether a specific construction satisfies a specific security property
  3. Finding a subtle error in a mathematical argument

Opus is NOT warranted for:
  - Paper reading or summarization → use sonnet
  - Synthesis across papers → use sonnet
  - Document writing or LaTeX editing → use sonnet
  - Code review → use sonnet
  - Literature search → use sonnet or haiku
  - Any task framed as 'tell me about X', 'write Y', 'find Z', or 'explain Q'

If this subagent does not meet criteria 1-3 above, downgrade to sonnet or haiku.
Per CLAUDE.md: never use opus without asking the user if the need is not clearly correctness-critical."
    jq -n --arg msg "$msg" '{systemMessage:$msg}'
    ;;
esac
