#!/bin/bash
# SubagentStart hook: warn when subagent uses opus
raw=$(jq -r '.model // empty')
case "$raw" in
  *opus*)
    msg="COST CHECK: This subagent is using opus. Per CLAUDE.md model selection rules:
- Default to haiku (simple search, lookups, formatting)
- Use sonnet for file editing, routine code, LaTeX, literature search
- Use opus ONLY for deep reasoning, proof verification, security analysis
Is opus justified here? If not, consider downgrading."
    jq -n --arg msg "$msg" '{systemMessage:$msg}'
    ;;
esac
