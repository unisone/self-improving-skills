---
description: Rate a skill's performance after use (self-improving skills OBSERVE layer — user feedback)
argument-hint: <skill-name> <good|bad> [notes]
allowed-tools: Bash
---

# Skill Feedback: $ARGUMENTS (Self-Improving Skills — OBSERVE/Feedback)

Parse the arguments: `<skill-name> <good|bad> [optional notes]`

If arguments are missing or malformed, ask the user:
1. Which skill? (show recent skills from `~/.claude/debug/skill-usage.jsonl` — last 10 unique names)
2. Rating: good or bad?
3. Optional notes (what went wrong or what worked well?)

Once you have the three values, append a feedback entry to `~/.claude/debug/skill-feedback.jsonl`:

Use `jq -n` to build the JSON safely (escape special characters in notes):

```bash
jq -n \
  --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
  --arg skill "SKILL_NAME" \
  --arg rating "RATING" \
  --arg notes "NOTES" \
  '{ts: $ts, skill: $skill, rating: $rating, notes: $notes}' \
  >> ~/.claude/debug/skill-feedback.jsonl
```

After saving, confirm:
- "Feedback recorded for **{skill}**: {rating}"
- If bad: "This will be flagged in the next `/audit-skills` run."
- If good: "This reinforces the skill's current approach."
