#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ensure_dir "$TARGET_AI_HOME"
ensure_dir "$TARGET_AI_HOME/bin"
ensure_dir "$TARGET_AI_HOME/agents/definitions"
ensure_dir "$TARGET_AI_HOME/systems/prompts"
ensure_dir "$TARGET_AI_HOME/infra/hooks"

require_repo_seed_dir
sync_seed_file_if_exists "cortex.md"
log "Prepared core harness directories under $TARGET_AI_HOME"
