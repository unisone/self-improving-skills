---
description: Roll back a skill to a previous version (self-improving skills AMEND layer — undo)
argument-hint: <skill-name> [version]
allowed-tools: Read, Bash, Write
---

# Skill Rollback: $ARGUMENTS (Self-Improving Skills — AMEND/Rollback)

Roll back a skill to a previous version. Parse arguments: `<skill-name> [optional version like v1, v2]`.

## Step 1: Find Available Versions

Check `~/.claude/skills/$SKILL_NAME/versions/` for:
- `SKILL.md.v*` files (sorted by version number)
- `manifest.jsonl` for version metadata (timestamps, reasons)

If no versions directory exists, report: "No version history found for this skill. The `/improve-skill` command creates backups before amending."

## Step 2: Show Version History

List all available versions with:
- Version number
- Timestamp (from manifest)
- Reason (from manifest)
- Size comparison with current

If no specific version was requested, show the list and ask which version to restore.

## Step 3: Restore

1. Back up the CURRENT version first (as the next version number, reason: "pre-rollback backup")
2. Copy the requested version over the current SKILL.md
3. Confirm: "Rolled back **{skill}** from current to **{version}** (created {timestamp})"

## Step 4: Log the Rollback

Append to `~/.claude/debug/skill-feedback.jsonl`:
```bash
jq -n --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" --arg skill "$SKILL_NAME" \
  --arg rating "bad" --arg notes "Rolled back to $VERSION — amendment did not improve outcomes" \
  '{ts: $ts, skill: $skill, rating: $rating, notes: $notes}' >> ~/.claude/debug/skill-feedback.jsonl
```

This negative feedback signal feeds back into the INSPECT layer.
