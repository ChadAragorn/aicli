#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

sync_subdir_if_exists "systems"
ensure_dir "$TARGET_AI_HOME/systems/prompts"
ensure_dir "$TARGET_AI_HOME/systems/contracts"
write_if_missing "$TARGET_AI_HOME/systems/README.md" "# Systems\n\nReusable system prompts and contracts."
