#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
require_repo_seed_dir

source_dir="$SOURCE_SEED_DIR/memory"
dest_dir="$TARGET_AI_HOME/memory"

if [[ ! -d "$source_dir" ]]; then
  skip "Source missing: $source_dir"
  exit 0
fi

ensure_dir "$dest_dir"
rsync -a --checksum --backup --suffix=".${TIMESTAMP}" \
  --exclude "*.swp" \
  --exclude "*.swo" \
  --exclude ".DS_Store" \
  --exclude "heartbeat-state.json" \
  --exclude "heartbeat-state.json.*" \
  "$source_dir/" "$dest_dir/"
log "Synced memory (excluding heartbeat state) -> $dest_dir"
