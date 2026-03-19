---
description: Audit Claude Code skills for effectiveness, staleness, and improvement opportunities (self-improving skills INSPECT layer)
allowed-tools: Read, Glob, Grep, Bash
---

# Skill Quality Audit (Self-Improving Skills — INSPECT)

You are performing an automated skill quality audit. This is the INSPECT step of the Observe→Inspect→Amend→Evaluate loop. Follow each step carefully and produce a structured report.

## Step 1: Gather Observation Data

### 1a. Usage data (invocations)
Read `~/.claude/debug/skill-usage.jsonl`. Each line:
```json
{"ts":"2026-03-14T12:00:00Z","skill":"commit","args":""}
```
Build a frequency table: skill name → invocation count, last used date.

### 1b. Outcome data (success/failure)
Read `~/.claude/debug/skill-outcomes.jsonl`. Each line:
```json
{"ts":"2026-03-14T12:00:05Z","skill":"commit","outcome":"success","error":""}
```
Build an outcome table: skill name → success count, error count, empty count, **failure rate** (errors / total).

### 1c. User feedback data
Read `~/.claude/debug/skill-feedback.jsonl`. Each line:
```json
{"ts":"2026-03-14T12:10:00Z","skill":"commit","rating":"good","notes":"worked perfectly"}
```
Build a feedback table: skill name → good count, bad count, latest notes.

If any file doesn't exist or is empty, note it and proceed with available data.

## Step 2: Inventory All Skills

List all skill directories in `~/.claude/skills/`. For each, check:
- Does SKILL.md exist?
- Last modified date (use `ls -la` via Bash)
- Size of the skill file

## Step 3: Gather Feedback Data

Search for ALL feedback memory files across ALL project memory directories:

```
~/.claude/projects/*/memory/*.md
```

Read each file's frontmatter. Collect files where `type: feedback`. Extract:
- The feedback rule/content
- The **Why** line (if present)
- Which project directory it belongs to

Also check `~/.claude/rules/*.md` — these are effectively "hardened feedback" (feedback that was promoted to a rule).

## Step 4: Correlate Feedback with Skills

For each feedback memory:
1. Check if it mentions a skill name (exact match against skill directory names)
2. Check if it describes a behavior that a specific skill should handle (semantic match)
3. Flag any skill that has accumulated negative feedback

## Step 5: Assess Staleness

For each skill, compute a staleness risk score:
- **High risk**: Not used in 30+ days AND last modified 60+ days ago
- **Medium risk**: Used but last modified 90+ days ago (may reference outdated APIs/patterns)
- **Low risk**: Recently used AND recently modified

## Step 6: Generate Report

Output a structured report with these sections:

### Skill Usage Summary
Show top 10 most-used skills and bottom 10 least-used. Include invocation count and last used date.

### Skills with Related Feedback
For each skill that has correlated feedback, show the skill name, the feedback content, and whether the feedback suggests the skill needs improvement.

### Staleness Warnings
List skills at medium or high staleness risk. Include last modified date and last used date.

### Outcome Analysis
For each skill with outcome data, show:
- Total runs, success rate, failure rate
- Most common error messages (if any)
- Skills with failure rate > 20% get flagged as **degraded**

### Top Improvement Candidates
Rank the top 5 skills most in need of improvement, using this priority:
1. **Critical**: High failure rate (>30%) + high usage = fix immediately
2. **High**: Negative user feedback + any usage = fix soon
3. **Medium**: High usage + staleness = review
4. **Low**: No usage + old = candidate for removal

For each candidate, provide:
- One-line recommendation (e.g., "Update React patterns to v19")
- Evidence source (outcome data / feedback / staleness)
- Suggested action: amend / review / remove

### Health Score
Calculate an overall skill health score (0-100):
- Start at 100
- -5 per skill with failure rate > 30% (degraded)
- -3 per skill with negative user feedback (bad rating)
- -2 per skill with failure rate 10-30%
- -1 per skill at high staleness risk
- -0.5 per skill never used
- +1 per skill with recent usage AND recent modification
- +2 per skill with >80% success rate AND good feedback

## Step 7: Save Results

Save the audit results as a memory file at the CURRENT PROJECT's memory directory:
`~/.claude/projects/{current-project}/memory/skill-audit-results.md`

Use `type: project` and include the date, health score, and top improvement candidates.

If a previous audit exists, compare scores to show trend (improving/declining/stable).

## Step 8: Reset Audit Timer

Update the audit marker so the automated reminder resets its countdown:

```bash
date +%s > ~/.claude/debug/last-skill-audit
```

This prevents the SessionStart reminder from firing until the next threshold is crossed (7 days or 50 invocations).
