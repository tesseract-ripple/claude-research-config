#!/bin/bash
# End-of-Day Agent Runner
# Kicks off background Claude tasks for overnight processing.
# Usage: eod-agents.sh [task...]
# Tasks: triage, papers, review, explore
# Example: eod-agents.sh triage papers
# Example: eod-agents.sh  (runs all tasks)
#
# Each task runs as a separate claude -p invocation and writes output
# to ~/claude-projects/eod-reports/YYYY-MM-DD/

set -euo pipefail

REPORT_DIR="$HOME/claude-projects/eod-reports/$(date +%Y-%m-%d)"
mkdir -p "$REPORT_DIR"

# Default: run all tasks
TASKS=("${@:-triage papers review explore}")
if [[ $# -eq 0 ]]; then
    TASKS=(triage papers review explore)
fi

log() {
    echo "[$(date +%H:%M:%S)] $*"
}

# --- Task: Triage open issues/PRs ---
run_triage() {
    log "Starting issue/PR triage..."
    # Find git repos in claude-projects and triage their issues
    for repo in ~/claude-projects/*/; do
        if [[ -d "$repo/.git" ]]; then
            repo_name=$(basename "$repo")
            remote=$(git -C "$repo" remote get-url origin 2>/dev/null || echo "")
            if [[ -z "$remote" ]]; then continue; fi

            log "  Triaging $repo_name..."
            (
                cd "$repo"
                claude -p "List the 20 most recent open issues and 10 most recent open PRs for this repository using gh. For each, provide: number, title, labels, age, and a 1-sentence assessment of effort (low/medium/high) and value (low/medium/high). Format as a markdown table. Focus on issues that could be good first contributions or quick wins." \
                    --allowedTools "Bash(gh *),Read,Grep" \
                    --output-format text \
                    > "$REPORT_DIR/triage_${repo_name}.md" 2>&1
            ) &
        fi
    done
    wait
    log "Triage complete."
}

# --- Task: Summarize recent papers ---
run_papers() {
    log "Starting paper digest..."
    # Process any PDFs dropped into the papers inbox
    INBOX="$HOME/claude-projects/papers-inbox"
    mkdir -p "$INBOX" "$INBOX/processed"

    for pdf in "$INBOX"/*.pdf; do
        [[ -f "$pdf" ]] || continue
        name=$(basename "$pdf" .pdf)
        log "  Summarizing $name..."
        claude -p "Read this PDF and produce a structured summary for a cryptography researcher. Include: (1) key contributions, (2) cryptographic assumptions, (3) proof technique, (4) efficiency metrics, (5) relevance to confidential transactions and commitment schemes. Be concise — under 400 words." \
            --allowedTools "Read" \
            --output-format text \
            < "$pdf" \
            > "$REPORT_DIR/paper_${name}.md" 2>&1
        mv "$pdf" "$INBOX/processed/"
    done
    log "Paper digest complete."
}

# --- Task: Review recent changes ---
run_review() {
    log "Starting code review..."
    for repo in ~/claude-projects/*/; do
        if [[ -d "$repo/.git" ]]; then
            repo_name=$(basename "$repo")
            # Check if there are recent commits (last 24h)
            recent=$(git -C "$repo" log --oneline --since="24 hours ago" 2>/dev/null | head -5)
            if [[ -z "$recent" ]]; then continue; fi

            log "  Reviewing recent changes in $repo_name..."
            (
                cd "$repo"
                claude -p "Review the git diff of all commits from the last 24 hours. Focus on: correctness, memory safety, cryptographic correctness (constant-time operations, secret zeroization), and any obvious bugs. Provide a concise report with file:line references for any issues found." \
                    --allowedTools "Bash(git *),Read,Grep" \
                    --output-format text \
                    > "$REPORT_DIR/review_${repo_name}.md" 2>&1
            ) &
        fi
    done
    wait
    log "Code review complete."
}

# --- Task: Explore a research direction ---
run_explore() {
    log "Starting research exploration..."
    # Check for exploration prompts in a simple text file
    PROMPTS_FILE="$HOME/claude-projects/explore-prompts.txt"
    if [[ ! -f "$PROMPTS_FILE" ]]; then
        log "  No explore-prompts.txt found, skipping."
        return
    fi

    i=0
    while IFS= read -r prompt; do
        [[ -z "$prompt" || "$prompt" == \#* ]] && continue
        i=$((i + 1))
        log "  Exploring: ${prompt:0:60}..."
        claude -p "$prompt" \
            --allowedTools "Read,Grep,Glob,WebSearch,WebFetch" \
            --output-format text \
            > "$REPORT_DIR/explore_${i}.md" 2>&1 &
    done < "$PROMPTS_FILE"
    wait

    # Clear processed prompts
    > "$PROMPTS_FILE"
    log "Research exploration complete."
}

# --- Run selected tasks ---
for task in "${TASKS[@]}"; do
    case "$task" in
        triage)  run_triage ;;
        papers)  run_papers ;;
        review)  run_review ;;
        explore) run_explore ;;
        *)       log "Unknown task: $task (valid: triage, papers, review, explore)" ;;
    esac
done

log "All EOD tasks complete. Reports in: $REPORT_DIR"

# macOS notification
osascript -e "display notification \"EOD agent reports ready in $REPORT_DIR\" with title \"Claude EOD\" sound name \"Glass\"" 2>/dev/null || true
