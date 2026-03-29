#!/bin/bash
# check-pending-tasks.sh
# Called by stuck-recovery hook on agentStop.
# Finds the first incomplete task in any active spec's tasks.md.
# If found, echoes a prompt back to Kiro's agent context to continue.
# Exit 0 = output goes to agent as context. Exit 1 = agent sees the error.

SPECS_DIR=".kiro/specs"
STATE_FILE=".kiro/state/session-state.json"

# Find the active spec (most recently modified tasks.md)
TASKS_FILE=$(find "$SPECS_DIR" -name "tasks.md" -exec ls -t {} + 2>/dev/null | head -1)

if [ -z "$TASKS_FILE" ]; then
  echo "No active spec found. Nothing to continue."
  exit 0
fi

# Find first unchecked task
NEXT_TASK=$(grep -m 1 "^\- \[ \]" "$TASKS_FILE" 2>/dev/null)

if [ -z "$NEXT_TASK" ]; then
  # All tasks done - mark complete in state
  mkdir -p .kiro/state
  echo "{\"status\": \"complete\", \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"spec\": \"$TASKS_FILE\"}" > "$STATE_FILE"
  echo "All tasks complete. State written to $STATE_FILE."
  exit 0
fi

# There is a pending task - output it so the agent picks it up and continues
echo "PENDING TASK DETECTED. Continue working on: $NEXT_TASK"
echo "Resume from $TASKS_FILE and complete this task now. Do not wait for user input. Follow all gdna steering standards."
exit 0
