#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="$REPO_ROOT/scripts/setup"

usage() {
  cat <<'EOF'
Usage:
  setup.sh [all|COMPONENT...]
  setup.sh list

Components:
  core memory tools skills plugins configs agents systems infra bin clients

Examples:
  ./setup.sh
  ./setup.sh all
  ./setup.sh list
  AI_HOME=/tmp/global ./setup.sh core memory tools skills plugins agents systems infra bin
  ./setup.sh clients
EOF
}

log() {
  printf '%s\n' "$*"
}

print_path_hint_if_needed() {
  local ai_home="${AI_HOME:-$HOME/.ai}"
  local tools_bin="$ai_home/tools/bin"
  local harness_bin="$ai_home/bin"
  local tools_home='$HOME/.ai/tools/bin'
  local harness_home='$HOME/.ai/bin'

  if [[ ":${PATH:-}:" != *":$tools_bin:"* || ":${PATH:-}:" != *":$harness_bin:"* ]]; then
    log ""
    log "PATH hint:"
    log "  export PATH=\"\$PATH:$harness_home:$tools_home\""
  fi
}

print_doc_vault_hint_if_needed() {
  if [[ -z "${DOC_VAULT_ROOT:-}" ]]; then
    log ""
    log "Documentation vault hint:"
    log "  export DOC_VAULT_ROOT=\"/path/to/your/documentation/vault\""
    return
  fi

  if [[ ! -d "$DOC_VAULT_ROOT" ]]; then
    log ""
    log "Documentation vault hint:"
    log "  DOC_VAULT_ROOT is set but path does not exist: $DOC_VAULT_ROOT"
    log "  update DOC_VAULT_ROOT to an existing local documentation vault path"
  fi
}

run_component() {
  local component="$1"
  local script="$SETUP_DIR/${component}.sh"
  [[ -x "$script" ]] || {
    printf 'Error: unknown component: %s\n' "$component" >&2
    exit 1
  }
  log "==> setup:$component"
  "$script"
}

describe_component() {
  local component="$1"
  case "$component" in
  core) echo "Create core harness directories and install root bootstrap (cortex.md)." ;;
  memory) echo "Sync shared memory files from repo seed/memory." ;;
  tools) echo "Sync shared tools from repo seed/tools." ;;
  skills) echo "Sync shared skills from repo seed/skills." ;;
  plugins) echo "Sync shared plugins from repo seed/plugins." ;;
  configs) echo "Sync shared config templates from repo seed/configs." ;;
  agents) echo "Validate and sync agent definitions from repo seed/agents." ;;
  systems) echo "Sync systems area and ensure systems/prompts and systems/contracts exist." ;;
  infra) echo "Sync infra area and ensure infra/hooks exists." ;;
  bin) echo "Install shared harness entrypoint (aih) into AI_HOME/bin." ;;
  clients) echo "Install client-specific configs into ~/.claude ~/.cursor ~/.codex ~/.gemini." ;;
  *) echo "Unknown component." ;;
  esac
}

list_components() {
  local components=(
    core
    memory
    tools
    skills
    plugins
    configs
    agents
    systems
    infra
    bin
    clients
  )
  for component in "${components[@]}"; do
    printf '%-8s %s\n' "$component" "$(describe_component "$component")"
  done
}

DEFAULT_COMPONENTS=(
  core
  memory
  tools
  skills
  plugins
  configs
  agents
  systems
  infra
  bin
)

args=("$@")
if [[ ${#args[@]} -eq 0 ]]; then
  args=("all")
fi

for arg in "${args[@]}"; do
  case "$arg" in
  list)
    list_components
    exit 0
    ;;
  -h | --help | help)
    usage
    exit 0
    ;;
  all)
    for component in "${DEFAULT_COMPONENTS[@]}"; do
      run_component "$component"
    done
    ;;
  core | memory | tools | skills | plugins | configs | agents | systems | infra | bin | clients)
    run_component "$arg"
    ;;
  *)
    printf 'Error: unknown component: %s\n' "$arg" >&2
    usage
    exit 1
    ;;
  esac
done

log "Setup complete."
print_path_hint_if_needed
print_doc_vault_hint_if_needed
