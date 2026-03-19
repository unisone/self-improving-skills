---
description: Evaluate whether a skill amendment improved outcomes (self-improving skills EVALUATE layer)
argument-hint: <skill-name>
allowed-tools: Read, Glob, Grep, Bash
---

# Evaluate Skill: $ARGUMENTS (Self-Improving Skills — EVALUATE)

This is the EVALUATE step — the final gate in the Observe→Inspect→Amend→Evaluate loop. A self-improving system must never be trusted simply because it can modify itself. Every amendment must be evaluated.

## Step 1: Find the Amendment Record

Search for amendment records for `$ARGUMENTS` in:
- `~/.claude/projects/*/memory/skill-amendments-log.md`

Extract:
- Amendment date
- Issues that were fixed
- Pre-state and post-state summaries

If no amendments found: "No amendments recorded for this skill. Run `/improve-skill $ARGUMENTS` first."

## Step 2: Gather Pre/Post Data

### Pre-amendment metrics (before the amendment date)
From `~/.claude/debug/skill-usage.jsonl` and `~/.claude/debug/skill-outcomes.jsonl`:
- Invocation count before amendment date
- Success/error rate before amendment date
- User feedback ratings before amendment date (from `skill-feedback.jsonl`)

### Post-amendment metrics (after the amendment date)
Same sources, but only entries AFTER the amendment date:
- Invocation count after amendment
- Success/error rate after amendment
- User feedback ratings after amendment

## Step 3: Compare

Build a comparison table:

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Total invocations | N | N | +/-N |
| Success rate | N% | N% | +/-N% |
| Error rate | N% | N% | +/-N% |
| Good feedback | N | N | +/-N |
| Bad feedback | N | N | +/-N |

## Step 4: Verdict

Based on the comparison:

- **IMPROVED**: Error rate decreased OR good feedback increased without new issues
- **NO CHANGE**: Metrics are statistically similar (not enough data yet)
- **DEGRADED**: Error rate increased OR bad feedback increased

If **DEGRADED**: Recommend rollback with `/skill-rollback $ARGUMENTS` and explain which metrics worsened.

If **NO CHANGE** and < 10 post-amendment invocations: "Insufficient data for evaluation. Wait for more usage and re-run."

## Step 5: Record Evaluation

Append evaluation result to the amendment log in project memory. Update the skill-audit-results if one exists (adjust the health score for this skill).

Format:
```
### Evaluation: [date]
- **Verdict**: IMPROVED | NO CHANGE | DEGRADED
- **Pre-metrics**: [summary]
- **Post-metrics**: [summary]
- **Recommendation**: Keep amendment | Roll back | Wait for data
```
