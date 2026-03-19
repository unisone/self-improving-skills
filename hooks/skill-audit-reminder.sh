#!/bin/bash
# Self-Improving Skills — Automated audit reminder
# SessionStart hook: checks if a skill audit is overdue
# Triggers on: startup, resume, clear, compact

set -e

USAGE_LOG="$HOME/.claude/debug/skill-usage.jsonl"
OUTCOMES_LOG="$HOME/.claude/debug/skill-outcomes.jsonl"
AUDIT_MARKER="$HOME/.claude/debug/last-skill-audit"

# Thresholds (customize these)
DAYS_THRESHOLD=7          # Remind after 7 days since last audit
INVOCATIONS_THRESHOLD=50  # Remind after 50 skill uses since last audit

# Initialize marker if missing
if [[ ! -f "$AUDIT_MARKER" ]]; then
    echo "0" > "$AUDIT_MARKER"  # epoch 0 = never audited
fi

LAST_AUDIT_EPOCH=$(cat "$AUDIT_MARKER" 2>/dev/null || echo "0")
NOW_EPOCH=$(date +%s)
DAYS_SINCE=$(( (NOW_EPOCH - LAST_AUDIT_EPOCH) / 86400 ))

# Count invocations since last audit
INVOCATIONS_SINCE=0
if [[ -f "$USAGE_LOG" ]]; then
    LAST_AUDIT_ISO=""
    if [[ "$LAST_AUDIT_EPOCH" -gt 0 ]]; then
        LAST_AUDIT_ISO=$(date -u -r "$LAST_AUDIT_EPOCH" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "1970-01-01T00:00:00Z")
    else
        LAST_AUDIT_ISO="1970-01-01T00:00:00Z"
    fi
    INVOCATIONS_SINCE=$(awk -F'"ts":"' -v cutoff="$LAST_AUDIT_ISO" '{split($2,a,"\""); if(a[1] > cutoff) count++} END{print count+0}' "$USAGE_LOG" 2>/dev/null || echo "0")
fi

# Count outcome errors since last audit
ERRORS_SINCE=0
if [[ -f "$OUTCOMES_LOG" ]]; then
    ERRORS_SINCE=$(grep -c '"outcome":"error"' "$OUTCOMES_LOG" 2>/dev/null; true)
    ERRORS_SINCE=${ERRORS_SINCE:-0}
fi

# Determine if reminder is needed
NEEDS_AUDIT=false
REASONS=""

if [[ "$LAST_AUDIT_EPOCH" -eq 0 ]]; then
    NEEDS_AUDIT=true
    REASONS="No audit has ever been run"
elif [[ "$DAYS_SINCE" -ge "$DAYS_THRESHOLD" ]]; then
    NEEDS_AUDIT=true
    REASONS="Last audit was ${DAYS_SINCE} days ago (threshold: ${DAYS_THRESHOLD})"
fi

if [[ "$INVOCATIONS_SINCE" -ge "$INVOCATIONS_THRESHOLD" ]]; then
    NEEDS_AUDIT=true
    if [[ -n "$REASONS" ]]; then
        REASONS="${REASONS}; ${INVOCATIONS_SINCE} skill invocations since last audit"
    else
        REASONS="${INVOCATIONS_SINCE} skill invocations since last audit (threshold: ${INVOCATIONS_THRESHOLD})"
    fi
fi

if [[ "$NEEDS_AUDIT" == "true" ]]; then
    # Build stats summary
    TOTAL_USAGE=$(wc -l < "$USAGE_LOG" 2>/dev/null | tr -d ' ' || echo "0")
    TOTAL_OUTCOMES=$(wc -l < "$OUTCOMES_LOG" 2>/dev/null | tr -d ' ' || echo "0")

    cat << EOF
[Self-Improving Skills] Audit recommended.
Reason: ${REASONS}
Stats: ${TOTAL_USAGE} total invocations, ${TOTAL_OUTCOMES} outcomes tracked, ${ERRORS_SINCE} errors detected.
Run /audit-skills to generate a health report, or /improve-skill <name> to fix a specific skill.
To dismiss until next threshold: touch ~/.claude/debug/last-skill-audit && date +%s > ~/.claude/debug/last-skill-audit
EOF
fi
