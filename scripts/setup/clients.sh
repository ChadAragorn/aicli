#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

SOURCE_CONFIG_DIR="$SOURCE_SEED_DIR/configs"
[[ -d "$SOURCE_CONFIG_DIR" ]] || die "Missing source configs directory at $SOURCE_CONFIG_DIR"

install_or_merge_claude_settings() {
  local source_file="$1"
  local dest_file="$2"
  local required_dir="$3"
  local tool_name="$4"
  local install_hint="$5"
  local hook_cmd="~/.ai/infra/hooks/session-start.sh"

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

  ensure_dir "$(dirname "$dest_file")"

  # First install uses seed template as-is.
  if [[ ! -f "$dest_file" ]]; then
    cp -p "$source_file" "$dest_file"
    log "Installed $tool_name config: $dest_file"
    return 0
  fi

  if ! command -v jq >/dev/null 2>&1; then
    warn "jq not found; cannot merge $tool_name settings without overwriting. Skipping."
    return 0
  fi

  local tmp_file
  tmp_file="$(mktemp)"
  jq --arg hook "$hook_cmd" '
    def has_cortex_hook:
      ((.hooks.SessionStart // [])
        | map(any((.hooks // [])[]?; (.type == "command" and .command == $hook)))
        | any);

    if has_cortex_hook then
      .
    else
      .hooks = (.hooks // {}) |
      .hooks.SessionStart = ((.hooks.SessionStart // []) + [{"hooks":[{"type":"command","command":$hook}]}])
    end
  ' "$dest_file" >"$tmp_file" || {
    rm -f "$tmp_file"
    warn "Could not parse $tool_name config as JSON: $dest_file"
    return 0
  }

  if cmp -s "$tmp_file" "$dest_file"; then
    rm -f "$tmp_file"
    log "$tool_name config unchanged: $dest_file"
    return 0
  fi

  backup_if_exists "$dest_file"
  cp -p "$tmp_file" "$dest_file"
  rm -f "$tmp_file"
  log "Merged $tool_name SessionStart hook into: $dest_file"
}

install_or_merge_claude_settings \
  "$SOURCE_CONFIG_DIR/claude_settings.json" \
  "$HOME/.claude/settings.json" \
  "$HOME/.claude" \
  "Claude" \
  "curl -fsSL https://claude.ai/install.sh | bash"

install_config_if_dir_exists \
  "$SOURCE_CONFIG_DIR/cursor_rules_ai-cortex-policy.mdc" \
  "$HOME/.cursor/rules/cortex-policy.mdc" \
  "$HOME/.cursor/rules" \
  "Cursor" \
  "curl https://cursor.com/install -fsS | bash"

install_config_if_dir_exists \
  "$SOURCE_CONFIG_DIR/codex_AGENTS.md" \
  "$HOME/.codex/AGENTS.md" \
  "$HOME/.codex" \
  "Codex" \
  "brew install codex (macOS) OR npm i -g @openai/codex (Linux). Codex CLI currently supports macOS/Linux only."

install_or_merge_gemini_settings() {
  local source_file="$1"
  local dest_file="$2"
  local required_dir="$3"
  local tool_name="$4"
  local install_hint="$5"
  local hook_cmd="~/.ai/infra/hooks/session-start.sh"

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

  ensure_dir "$(dirname "$dest_file")"

  if [[ ! -f "$dest_file" ]]; then
    cp -p "$source_file" "$dest_file"
    log "Installed $tool_name config: $dest_file"
    return 0
  fi

  if ! command -v jq >/dev/null 2>&1; then
    warn "jq not found; cannot merge $tool_name settings without overwriting. Skipping."
    return 0
  fi

  local tmp_file
  tmp_file="$(mktemp)"
  jq --arg hook "$hook_cmd" '
    def has_cortex_hook:
      ((.hooks.SessionStart // [])
        | map(any((.hooks // [])[]?; (.type == "command" and .command == $hook)))
        | any);

    if has_cortex_hook then
      .
    else
      .hooks = (.hooks // {}) |
      .hooks.SessionStart = ((.hooks.SessionStart // []) + [{"matcher":"*","hooks":[{"name":"cortex_loader","type":"command","command":$hook,"timeout":5000}]}])
    end
  ' "$dest_file" >"$tmp_file" || {
    rm -f "$tmp_file"
    warn "Could not parse $tool_name config as JSON: $dest_file"
    return 0
  }

  if cmp -s "$tmp_file" "$dest_file"; then
    rm -f "$tmp_file"
    log "$tool_name config unchanged: $dest_file"
    return 0
  fi

  backup_if_exists "$dest_file"
  cp -p "$tmp_file" "$dest_file"
  rm -f "$tmp_file"
  log "Merged $tool_name SessionStart hook into: $dest_file"
}

install_or_merge_gemini_settings \
  "$SOURCE_CONFIG_DIR/gemini_settings.json" \
  "$HOME/.gemini/settings.json" \
  "$HOME/.gemini" \
  "Gemini CLI" \
  "brew install gemini-cli (macOS) OR npm install -g @google/gemini-cli (Linux/Windows)"
