---
description: Scaffold a new Claude Code skill from a task description (self-improving skills BOOTSTRAP layer)
argument-hint: <task description>
allowed-tools: Read, Glob, Grep, Write, Edit
---

# Bootstrap Skill: $ARGUMENTS (Self-Improving Skills — BOOTSTRAP)

You are scaffolding a brand-new skill from the task description `$ARGUMENTS`.
A good skill is a reusable playbook: it triggers on a recognizable situation
and teaches the agent a workflow it can follow reliably.

## Step 1: Understand the Task

Clarify what the skill should do:

- **Trigger** — what situation invokes it? ("when reviewing a PR", "before a release")
- **Outcome** — what does "done" look like?
- **Scope** — what is explicitly out of scope?

If the description is vague, ask 2-3 targeted questions before writing anything.
A skill built on a fuzzy task stays fuzzy forever.

## Step 2: Check for Overlap

Search `~/.claude/skills/` for existing skills covering this task:

- If one exists and mostly fits → suggest `/improve-skill` on it instead of
  creating a duplicate.
- If one exists and partially fits → define the new skill's boundary against it
  explicitly in the description ("Use when X; the existing Y skill covers Z").

## Step 3: Draft the SKILL.md

Write the skill to `~/.claude/skills/<skill-name>/SKILL.md` following the
Agent Skills spec:

```markdown
---
name: <kebab-case-name>
description: <what it does + WHEN to use it, trigger-oriented, third person>
license: MIT
---

# <Title>

<One-paragraph purpose statement.>

## Usage
<Concrete commands or invocation patterns.>

## Process
<Numbered steps the agent follows. Be specific enough to execute.>

## Output
<What the agent produces, with format examples.>

## Anti-patterns / Boundaries
<What the skill does NOT do.>
```

Frontmatter rules:

- `description` must contain trigger phrases ("Use when...", "Before...").
  This is what the model matches against — a description without triggers
  is a skill that never fires.
- `name` is kebab-case, no namespaces, no colons.
- Keep the body under ~300 lines. Long skills don't get read; split
  reference material into `references/` files and link them.

## Step 4: Validate

Before declaring it done:

1. Re-read the draft and ask: could an agent follow this without asking
   clarifying questions? If not, tighten the steps.
2. Run `/skill-evaluate <skill-name>` to score it against the quality rubric.
3. If it scores below the bar, iterate — don't ship a weak skill.

## Step 5: Register

- Add it to the skill index so `/audit-skills` picks it up.
- Log the creation in the skills changelog: what task it covers, why it's new
  rather than an improvement to an existing skill.
