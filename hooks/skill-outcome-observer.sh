#!/bin/bash
# Self-Improving Skills — OBSERVE layer (outcomes)
# PostToolUse hook: captures whether a Skill invocation succeeded or failed
# Pairs with skill-observer.sh (PreToolUse) to complete the observation picture

set -e
umask 077

LOG_FILE="$HOME/.claude/debug/skill-outcomes.jsonl"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null

HOOK_INPUT=$(cat)

TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")

if [[ "$TOOL_NAME" == "Skill" ]]; then
    SKILL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_input.skill // "unknown"' 2>/dev/null || echo "unknown")
    TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    # Extract the tool response (may be large — take first 2000 chars for analysis)
    RESPONSE=$(echo "$HOOK_INPUT" | jq -r '.tool_response // .response // ""' 2>/dev/null | head -c 2000 || echo "")

    # Determine outcome by checking for error indicators
    OUTCOME="success"
    ERROR_MSG=""

    if echo "$RESPONSE" | grep -qiE '(error|failed|failure|exception|not found|cannot|unable to|refused|timeout|ENOENT|EACCES|crashed)'; then
        OUTCOME="error"
        # Extract first error-like line (up to 200 chars)
        ERROR_MSG=$(echo "$RESPONSE" | grep -iE '(error|failed|failure|exception|not found|cannot|unable to|refused|timeout)' | head -1 | head -c 200 || echo "")
    fi

    # Check if response is empty (another failure indicator)
    if [[ -z "$RESPONSE" ]]; then
        OUTCOME="empty"
        ERROR_MSG="No response from skill"
    fi

    # Build JSON safely using jq
    jq -n \
        --arg ts "$TIMESTAMP" \
        --arg skill "$SKILL_NAME" \
        --arg outcome "$OUTCOME" \
        --arg error "$ERROR_MSG" \
        '{ts: $ts, skill: $skill, outcome: $outcome, error: $error}' \
        >> "$LOG_FILE" 2>/dev/null
fi
