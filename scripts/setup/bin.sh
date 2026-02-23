#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ensure_dir "$TARGET_AI_HOME/bin"

if [[ -f "$REPO_ROOT/seed/bin/aih" ]]; then
  cp -p "$REPO_ROOT/seed/bin/aih" "$TARGET_AI_HOME/bin/aih"
  chmod +x "$TARGET_AI_HOME/bin/aih"
  log "Installed aih -> $TARGET_AI_HOME/bin/aih"
fi
