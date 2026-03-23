#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ensure_dir "$TARGET_AI_HOME/bin"

if [[ -d "$REPO_ROOT/seed/bin" ]]; then
  for source in "$REPO_ROOT"/seed/bin/*; do
    [[ -f "$source" ]] || continue
    name="$(basename "$source")"
    dest="$TARGET_AI_HOME/bin/$name"
    cp -p "$source" "$dest"
    chmod +x "$dest"
    log "Installed $name -> $dest"
  done
fi
