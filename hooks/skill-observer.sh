#!/bin/bash
# Self-Improving Skills — OBSERVE layer
# Tracks every Skill tool invocation for usage analysis
# PreToolUse hook: always allows, just logs

set -e
umask 077

LOG_FILE="$HOME/.claude/debug/skill-usage.jsonl"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null

HOOK_INPUT=$(cat)

TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")

if [[ "$TOOL_NAME" == "Skill" ]]; then
    SKILL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_input.skill // "unknown"' 2>/dev/null || echo "unknown")
    SKILL_ARGS=$(echo "$HOOK_INPUT" | jq -r '.tool_input.args // ""' 2>/dev/null || echo "")
    TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    # Build JSON safely using jq (not printf) to prevent injection
    jq -n \
        --arg ts "$TIMESTAMP" \
        --arg skill "$SKILL_NAME" \
        --arg args "$SKILL_ARGS" \
        '{ts: $ts, skill: $skill, args: $args}' \
        >> "$LOG_FILE" 2>/dev/null
fi

# PreToolUse must return a decision — always allow
echo '{"decision":"allow"}'
