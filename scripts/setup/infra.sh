#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

sync_subdir_if_exists "infra"
ensure_dir "$TARGET_AI_HOME/infra/hooks"
write_if_missing "$TARGET_AI_HOME/infra/README.md" "# Infrastructure\n\nShared hooks and integration scripts."
