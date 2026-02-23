#!/usr/bin/env bash

# Harness SessionStart Hook
# Loads ONLY the curated harness bootstrap contract (cortex.md)
# Component files are then loaded according to cortex instructions.

MEMORY_DIR="$HOME/.ai"
GLOBAL_CORTEX="$MEMORY_DIR/cortex.md"

# Load cortex.md (curated harness bootstrap contract)
if [[ -f "$GLOBAL_CORTEX" ]]; then
  CONTENT=$(cat "$GLOBAL_CORTEX")
  ESCAPED_CONTENT=$(jq -Rs . <<< "$CONTENT")

  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $ESCAPED_CONTENT
  }
}
EOF
else
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart"
  },
  "systemMessage": "Harness initialized. Create ~/.ai/cortex.md to enable shared bootstrap context."
}
EOF
fi
