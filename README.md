# Self-Improving Skills for Claude Code

A closed-loop system that makes your AI agent skills **self-improving**. Skills are static files operating in dynamic environments — they degrade silently. This system detects degradation, proposes fixes, and verifies those fixes actually helped.

```
OBSERVE  →  INSPECT  →  AMEND  →  EVALUATE
   ↑                                    |
   └────────────────────────────────────┘
```

Inspired by [@tricalt's viral post](https://x.com/tricalt/status/2032179887277060476) on cognee-skills (1.6M+ views). This is the pure Claude Code implementation — shell scripts + markdown commands, zero external dependencies.

## What's Included

| Layer | Component | Type | Purpose |
|-------|-----------|------|---------|
| **OBSERVE** | `skill-observer.sh` | PreToolUse hook | Logs every skill invocation |
| **OBSERVE** | `skill-outcome-observer.sh` | PostToolUse hook | Logs success/failure of each skill |
| **OBSERVE** | `skill-feedback.md` | Slash command | Manual good/bad rating after use |
| **INSPECT** | `audit-skills.md` | Slash command | Full health audit with scoring |
| **AMEND** | `improve-skill.md` | Slash command | Evidence-based amendments with backups |
| **AMEND** | `skill-rollback.md` | Slash command | Undo amendments, restore versions |
| **EVALUATE** | `skill-evaluate.md` | Slash command | Pre/post comparison, verdict |
| **AUTOMATE** | `skill-audit-reminder.sh` | SessionStart hook | Nudges when audit is overdue |

## Quick Install

### Option A: Claude Code plugin (recommended)

```
/plugin install self-improving-skills@unisone/self-improving-skills
```

Hooks register automatically through the plugin. No `settings.json` editing needed.

### Option B: Install script

```bash
git clone https://github.com/unisone/self-improving-skills.git
cd self-improving-skills
chmod +x install.sh
./install.sh
```

The install script:
1. Copies hooks to `~/.claude/hooks/`
2. Copies commands to `~/.claude/commands/`
3. Creates the `~/.claude/debug/` data directory
4. Shows you the JSON to add to `~/.claude/settings.json`

## Manual Install

If you prefer to install manually:

### 1. Copy hooks

```bash
mkdir -p ~/.claude/hooks ~/.claude/debug
cp hooks/skill-observer.sh ~/.claude/hooks/
cp hooks/skill-outcome-observer.sh ~/.claude/hooks/
cp hooks/skill-audit-reminder.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/skill-observer.sh
chmod +x ~/.claude/hooks/skill-outcome-observer.sh
chmod +x ~/.claude/hooks/skill-audit-reminder.sh
```

### 2. Copy commands

```bash
mkdir -p ~/.claude/commands
cp commands/audit-skills.md ~/.claude/commands/
cp commands/improve-skill.md ~/.claude/commands/
cp commands/skill-feedback.md ~/.claude/commands/
cp commands/skill-evaluate.md ~/.claude/commands/
cp commands/skill-rollback.md ~/.claude/commands/
```

### 3. Register hooks in settings.json

Add the following to your `~/.claude/settings.json` under the `hooks` key:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Skill",
        "hooks": [{
          "type": "command",
          "command": "~/.claude/hooks/skill-observer.sh",
          "timeout": 5,
          "statusMessage": "Tracking skill usage..."
        }]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Skill",
        "hooks": [{
          "type": "command",
          "command": "~/.claude/hooks/skill-outcome-observer.sh",
          "timeout": 5,
          "statusMessage": "Recording skill outcome..."
        }]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [{
          "type": "command",
          "command": "~/.claude/hooks/skill-audit-reminder.sh",
          "timeout": 5
        }]
      }
    ]
  }
}
```

### 4. Restart Claude Code

The hooks start collecting data immediately.

## Usage

### Daily workflow (automatic)

Just use Claude Code normally. The hooks silently log:
- Every skill invocation → `~/.claude/debug/skill-usage.jsonl`
- Every skill outcome → `~/.claude/debug/skill-outcomes.jsonl`
- Audit reminders on session start (after 7 days or 50 invocations)

### When you notice a skill misbehaving

```
/skill-feedback brainstorming bad "Too many options, ignores constraints"
```

### Weekly audit (prompted automatically)

```
/audit-skills
```

Produces a health report with:
- Usage frequency per skill
- Success/failure rates
- Feedback correlation
- Staleness warnings
- Top 5 improvement candidates
- Overall health score (0-100)

### Fix a flagged skill

```
/improve-skill brainstorming
```

This:
1. Reads the skill + all evidence
2. Proposes targeted amendments
3. Backs up the current version
4. Applies changes with your confirmation
5. Logs the amendment for evaluation

### Verify the fix worked

```
/skill-evaluate brainstorming
```

Compares pre/post metrics. Verdict: IMPROVED, NO CHANGE, or DEGRADED.

### Roll back if it didn't

```
/skill-rollback brainstorming
```

Restores the previous version and logs a negative signal.

## Data Files

All observation data is stored as JSONL (one JSON object per line):

| File | Contents |
|------|----------|
| `~/.claude/debug/skill-usage.jsonl` | `{ts, skill, args}` per invocation |
| `~/.claude/debug/skill-outcomes.jsonl` | `{ts, skill, outcome, error}` per completion |
| `~/.claude/debug/skill-feedback.jsonl` | `{ts, skill, rating, notes}` per user rating |
| `~/.claude/debug/last-skill-audit` | Epoch timestamp of last audit |

Skill version backups live in `~/.claude/skills/<name>/versions/`.

## Configuration

Edit thresholds in `skill-audit-reminder.sh`:

```bash
DAYS_THRESHOLD=7          # Days between audit reminders
INVOCATIONS_THRESHOLD=50  # Skill uses between reminders
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `jq` (for JSON processing in hooks)
- Bash 4+

## Architecture

```
HOOKS (automatic, every session):
  PreToolUse  → skill-observer.sh        → skill-usage.jsonl
  PostToolUse → skill-outcome-observer.sh → skill-outcomes.jsonl
  SessionStart → skill-audit-reminder.sh  → stdout (reminder)

COMMANDS (human-triggered):
  /skill-feedback  → skill-feedback.jsonl
  /audit-skills    → health report + score
  /improve-skill   → versioned amendments
  /skill-evaluate  → pre/post comparison
  /skill-rollback  → restore previous version

DATA FLOW:
  observe (3 JSONL files)
    → inspect (/audit-skills reads all 3)
      → amend (/improve-skill with backup)
        → evaluate (/skill-evaluate compares)
          → back to observe (loop continues)
```

## Credits

- Concept: [@tricalt](https://x.com/tricalt) / [cognee-skills](https://github.com/topoteretes/cognee)
- Implementation: [Alex Zaytsev](https://github.com/unisone)

## License

MIT

