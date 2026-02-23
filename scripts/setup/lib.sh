#!/usr/bin/env bash

set -euo pipefail

TIMESTAMP="$(date +%Y%m%d%H%M%S)"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_SEED_DIR="$REPO_ROOT/seed"
TARGET_AI_HOME="${AI_HOME:-$HOME/.ai}"

log() {
  printf '%s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

skip() {
  printf 'SKIP: %s\n' "$*"
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

ensure_dir() {
  mkdir -p "$1"
}

backup_if_exists() {
  local target_file="$1"
  if [[ -f "$target_file" ]]; then
    local backup_file="${target_file}.${TIMESTAMP}"
    cp -p "$target_file" "$backup_file"
    log "Backed up $target_file -> $backup_file"
  fi
}

files_identical() {
  local left="$1"
  local right="$2"
  [[ -f "$left" && -f "$right" ]] && cmp -s "$left" "$right"
}

sync_subdir_if_exists() {
  local subdir="$1"
  local source="$SOURCE_SEED_DIR/$subdir"
  local dest="$TARGET_AI_HOME/$subdir"

  if [[ ! -d "$source" ]]; then
    skip "Source missing: $source"
    return 0
  fi

  ensure_dir "$dest"
  rsync -a --checksum --backup --suffix=".${TIMESTAMP}" \
    --exclude "*.swp" \
    --exclude "*.swo" \
    --exclude ".DS_Store" \
    "$source/" "$dest/"
  log "Synced $subdir -> $dest"
}

write_if_missing() {
  local file="$1"
  local content="$2"
  if [[ ! -f "$file" ]]; then
    printf '%s\n' "$content" >"$file"
    log "Created $file"
  fi
}

sync_seed_file_if_exists() {
  local rel_path="$1"
  local source="$SOURCE_SEED_DIR/$rel_path"
  local dest="$TARGET_AI_HOME/$rel_path"

  if [[ ! -f "$source" ]]; then
    skip "Source file missing: $source"
    return 0
  fi

  ensure_dir "$(dirname "$dest")"
  if files_identical "$source" "$dest"; then
    log "Unchanged $dest"
    return 0
  fi

  backup_if_exists "$dest"
  cp -p "$source" "$dest"
  log "Installed $rel_path -> $dest"
}

install_config_if_dir_exists() {
  local source_file="$1"
  local dest_file="$2"
  local required_dir="$3"
  local tool_name="$4"
  local install_hint="$5"

  if [[ ! -f "$source_file" ]]; then
    warn "Source config missing for $tool_name: $source_file"
    return 1
  fi

  if [[ ! -d "$required_dir" ]]; then
    skip "$tool_name config not installed (missing directory: $required_dir)"
    if [[ -n "$install_hint" ]]; then
      log "      Install hint: $install_hint"
    fi
    return 0
  fi

  if files_identical "$source_file" "$dest_file"; then
    log "$tool_name config unchanged: $dest_file"
    return 0
  fi

  backup_if_exists "$dest_file"
  ensure_dir "$(dirname "$dest_file")"
  if cp -p "$source_file" "$dest_file"; then
    log "Installed $tool_name config: $dest_file"
  else
    warn "Could not install $tool_name config to $dest_file (permission or policy issue)"
  fi
}

require_repo_seed_dir() {
  [[ -d "$SOURCE_SEED_DIR" ]] || die "Missing source seed directory at $SOURCE_SEED_DIR"
}
