#!/usr/bin/env bash

# Memory Plugin - SessionStart Hook
# Loads ONLY the curated long-term memory (MEMORY.md)
# Session files in ~/.ai/memory/ are searched on-demand using rg/Grep

MEMORY_DIR="$HOME/.ai"
GLOBAL_MEMORY="$MEMORY_DIR/MEMORY.md"

# Load MEMORY.md (curated long-term memory)
if [[ -f "$GLOBAL_MEMORY" ]]; then
  CONTENT=$(cat "$GLOBAL_MEMORY")
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
  "systemMessage": "Memory system initialized. Create ~/.ai/MEMORY.md to enable persistent memory."
}
EOF
fi
