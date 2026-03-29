#!/bin/bash
# report-state.sh
# Called by stage-complete hook on agentStop.
# Writes current session state to .kiro/state/session-state.json and commits to git.
# Cowork monitors this file via GitHub to know when a stage is done.

STATE_DIR=".kiro/state"
STATE_FILE="$STATE_DIR/session-state.json"
SPECS_DIR=".kiro/specs"

mkdir -p "$STATE_DIR"

# Count total and completed tasks across all active specs
TOTAL=$(grep -r "^\- \[" "$SPECS_DIR" 2>/dev/null | wc -l | tr -d ' ')
DONE=$(grep -r "^\- \[x\]" "$SPECS_DIR" 2>/dev/null | wc -l | tr -d ' ')
PENDING=$(grep -r "^\- \[ \]" "$SPECS_DIR" 2>/dev/null | wc -l | tr -d ' ')

# Determine status
if [ "$PENDING" -eq 0 ] && [ "$TOTAL" -gt 0 ]; then
  STATUS="complete"
elif [ "$DONE" -gt 0 ]; then
  STATUS="in_progress"
else
  STATUS="started"
fi

# Write state file
cat > "$STATE_FILE" << EOF
{
  "status": "$STATUS",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "tasks_total": $TOTAL,
  "tasks_done": $DONE,
  "tasks_pending": $PENDING,
  "machine": "$(hostname)",
  "branch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
}
EOF

# Commit state back to git so Cowork can read it
git add "$STATE_FILE" 2>/dev/null
git commit -m "chore: update session state [$STATUS] $DONE/$TOTAL tasks" --no-verify 2>/dev/null

echo "State written: $STATUS ($DONE/$TOTAL tasks complete)"
exit 0
