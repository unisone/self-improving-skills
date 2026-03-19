#!/bin/bash
# Self-Improving Skills — OBSERVE layer
# Tracks every Skill tool invocation for usage analysis
# PreToolUse hook: always allows, just logs

set -e

LOG_FILE="$HOME/.claude/debug/skill-usage.jsonl"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null

HOOK_INPUT=$(cat)

TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")

if [[ "$TOOL_NAME" == "Skill" ]]; then
    SKILL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_input.skill // "unknown"' 2>/dev/null || echo "unknown")
    SKILL_ARGS=$(echo "$HOOK_INPUT" | jq -r '.tool_input.args // ""' 2>/dev/null || echo "")
    TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    # Append to JSONL log (one JSON object per line)
    printf '{"ts":"%s","skill":"%s","args":"%s"}\n' \
        "$TIMESTAMP" \
        "$SKILL_NAME" \
        "$(echo "$SKILL_ARGS" | tr '"' "'" | tr '\n' ' ')" \
        >> "$LOG_FILE" 2>/dev/null
fi

# PreToolUse must return a decision — always allow
echo '{"decision":"allow"}'
