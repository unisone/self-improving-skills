---
description: Propose and apply targeted improvements to a specific Claude Code skill (self-improving skills AMEND layer)
argument-hint: <skill-name>
allowed-tools: Read, Glob, Grep, Write, Edit
---

# Improve Skill: $ARGUMENTS (Self-Improving Skills — AMEND)

You are proposing targeted improvements to the skill `$ARGUMENTS`. This is the AMEND step of the Observe→Inspect→Amend→Evaluate loop. Changes must be evidence-based, minimal, and reversible.

## Step 1: Read the Current Skill

Read `~/.claude/skills/$ARGUMENTS/SKILL.md` (the main skill definition).
Also check for:
- `~/.claude/skills/$ARGUMENTS/README.md`
- `~/.claude/skills/$ARGUMENTS/rules/*.md`
- `~/.claude/skills/$ARGUMENTS/references/*.md`

Understand the skill's purpose, trigger conditions, content structure, and scope.

## Step 2: Gather Evidence

### Usage data
Read `~/.claude/debug/skill-usage.jsonl` and filter for this skill. Note:
- Total invocations
- Frequency trend (increasing/decreasing)
- Common args patterns

### Feedback data
Search all project memory directories for feedback that relates to this skill:
```
~/.claude/projects/*/memory/*.md
```
Look for `type: feedback` files that mention the skill name or describe behaviors this skill should handle.

### Previous audit
Check if `skill-audit-results.md` exists in any project memory. See if this skill was flagged.

## Step 3: Identify Issues

Based on evidence, classify issues into:

1. **Description too vague** — Trigger description doesn't capture all relevant scenarios
2. **Missing content** — Skill lacks guidance for a common use case or edge case
3. **Outdated patterns** — References old API versions, deprecated methods, or obsolete conventions
4. **Missing examples** — Key concepts lack concrete code examples
5. **Overly broad scope** — Skill tries to cover too much, reducing signal-to-noise
6. **Contradicts feedback** — Skill's guidance conflicts with explicit user feedback/corrections

## Step 4: Propose Amendments

For each issue, propose a **targeted, minimal change**:

### Amendment Format
```
**Issue #N**: [category] — one-line description
**Location**: SKILL.md, line range or section name
**Current text**:
> [exact current text to replace]
**Proposed text**:
> [replacement text]
**Rationale**: Why this change fixes the issue
**Evidence**: Which feedback/usage data supports this
**Confidence**: high | medium | low
```

### Amendment Rules
- Keep changes under 300 characters of new content per amendment
- Never rewrite the entire skill — only change what's broken
- Preserve existing formatting and structure
- If adding new content, insert it in the most relevant existing section
- Maximum 5 amendments per skill per invocation
- Do NOT change the skill's name or description unless that's the identified issue

## Step 5: Backup Before Amending (Version Control)

Before applying any changes, create a versioned backup:

1. Check if `~/.claude/skills/$ARGUMENTS/versions/` exists — create it if not
2. Determine next version number: count existing `SKILL.md.v*` files + 1
3. Copy current SKILL.md to `~/.claude/skills/$ARGUMENTS/versions/SKILL.md.v{N}`
4. Record the version in a `versions/manifest.jsonl` file:
```bash
jq -n --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" --arg ver "v{N}" --arg reason "pre-amendment backup" \
  '{ts: $ts, version: $ver, reason: $reason}' >> ~/.claude/skills/$ARGUMENTS/versions/manifest.jsonl
```

This ensures any amendment can be rolled back with `/skill-rollback`.

## Step 6: Apply with Confirmation

Present all proposed amendments as a numbered list. Ask the user:
"Apply these amendments? (all / specific numbers / none)"

If approved:
1. Apply each amendment using the Edit tool
2. Verify the file is still valid markdown after edits

## Step 7: Record the Amendment

After applying, save a record to the current project's memory:

Create or update `~/.claude/projects/{current-project}/memory/skill-amendments-log.md`:

```markdown
---
name: Skill Amendment Log
description: Record of all skill amendments for self-improvement evaluation
type: project
---

## [date] — $ARGUMENTS
- **Issues fixed**: [list]
- **Amendments applied**: [count]
- **Evidence basis**: [feedback/usage/staleness]
- **Pre-state**: [brief summary of what was wrong]
- **Post-state**: [brief summary of what was changed]
```

This log enables the EVALUATE step — future audits can compare skill effectiveness before and after amendments.
