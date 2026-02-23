#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

validate_agent_file() {
  local file="$1"
  local ok=1
  local frontmatter
  local required_keys
  required_keys="id name purpose model skills tools"

  # Parse YAML frontmatter block (between first two --- lines).
  frontmatter="$(awk '
    BEGIN {fm=0}
    /^---[[:space:]]*$/ && fm==0 {fm=1; next}
    /^---[[:space:]]*$/ && fm==1 {exit}
    fm==1 {print}
  ' "$file")"

  if [[ -z "$frontmatter" ]]; then
    warn "Invalid agent definition ($file): missing YAML frontmatter"
    return 1
  fi

  for key in $required_keys; do
    if ! printf "%s\n" "$frontmatter" | rg -q "^[[:space:]]*${key}:[[:space:]]*"; then
      warn "Invalid agent definition ($file): missing key '$key'"
      ok=0
    fi
  done

  local id_value
  local expected_id
  id_value="$(printf "%s\n" "$frontmatter" | sed -nE "s/^[[:space:]]*id:[[:space:]]*['\"]?([^'\"]+)['\"]?[[:space:]]*$/\1/p" | head -n 1)"
  expected_id="$(basename "$file" .md)"
  if [[ -z "$id_value" ]]; then
    warn "Invalid agent definition ($file): empty id"
    ok=0
  elif [[ "$id_value" != "$expected_id" ]]; then
    warn "Invalid agent definition ($file): id '$id_value' must match filename '$expected_id'"
    ok=0
  fi

  if [[ "$ok" -eq 0 ]]; then
    return 1
  fi
}

validate_agents_tree() {
  local definitions_dir="$SOURCE_SEED_DIR/agents/definitions"
  if [[ ! -d "$definitions_dir" ]]; then
    return 0
  fi

  local failures=0
  local found=0
  while IFS= read -r file; do
    found=1
    if ! validate_agent_file "$file"; then
      failures=$((failures + 1))
    fi
  done < <(find "$definitions_dir" -type f -name "*.md" | sort)

  if [[ "$found" -eq 0 ]]; then
    warn "No agent definitions found in $definitions_dir"
    return 0
  fi

  if [[ "$failures" -gt 0 ]]; then
    die "Agent validation failed with $failures invalid definition(s)"
  fi

  log "Validated agent definitions in $definitions_dir"
}

validate_agents_tree
sync_subdir_if_exists "agents"
ensure_dir "$TARGET_AI_HOME/agents/definitions"
write_if_missing "$TARGET_AI_HOME/agents/README.md" "# Agents\n\nShared agent definitions live in definitions/*.md with YAML frontmatter.\nEach definition must include id, name, purpose, model, skills, and tools."
