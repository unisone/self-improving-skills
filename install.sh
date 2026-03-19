#!/bin/bash
# Self-Improving Skills — Installer for Claude Code
# Copies hooks and commands to the right locations

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Self-Improving Skills Installer ==="
echo ""

# Check for jq
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required but not installed."
    echo "Install with: brew install jq (macOS) or apt install jq (Linux)"
    exit 1
fi

# Create directories
mkdir -p ~/.claude/hooks
mkdir -p ~/.claude/commands
mkdir -p ~/.claude/debug
echo "[OK] Created directories"

# Copy hooks
cp "$SCRIPT_DIR/hooks/skill-observer.sh" ~/.claude/hooks/
cp "$SCRIPT_DIR/hooks/skill-outcome-observer.sh" ~/.claude/hooks/
cp "$SCRIPT_DIR/hooks/skill-audit-reminder.sh" ~/.claude/hooks/
chmod +x ~/.claude/hooks/skill-observer.sh
chmod +x ~/.claude/hooks/skill-outcome-observer.sh
chmod +x ~/.claude/hooks/skill-audit-reminder.sh
echo "[OK] Installed 3 hooks"

# Copy commands
cp "$SCRIPT_DIR/commands/audit-skills.md" ~/.claude/commands/
cp "$SCRIPT_DIR/commands/improve-skill.md" ~/.claude/commands/
cp "$SCRIPT_DIR/commands/skill-feedback.md" ~/.claude/commands/
cp "$SCRIPT_DIR/commands/skill-evaluate.md" ~/.claude/commands/
cp "$SCRIPT_DIR/commands/skill-rollback.md" ~/.claude/commands/
echo "[OK] Installed 5 commands"

echo ""
echo "=== Almost done! ==="
echo ""
echo "Add the following hooks to your ~/.claude/settings.json"
echo "(merge into the existing 'hooks' object if you have one):"
echo ""
cat << 'HOOKSJSON'
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
HOOKSJSON

echo ""
echo "Then restart Claude Code. The system will start collecting data immediately."
echo ""
echo "Available commands:"
echo "  /audit-skills              — Run a full health audit"
echo "  /skill-feedback <name> <good|bad> [notes]  — Rate a skill"
echo "  /improve-skill <name>      — Fix a flagged skill"
echo "  /skill-evaluate <name>     — Verify a fix helped"
echo "  /skill-rollback <name>     — Undo an amendment"
echo ""
echo "=== Installation complete ==="
