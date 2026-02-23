#!/usr/bin/env bash
set -euo pipefail

HARNESS_ROOT="/etc/aih"
AI_HOME="${AI_HOME:-$HOME/.ai}"

ensure_venv_activation_in_bashrc() {
    local bashrc="$HOME/.bashrc"
    local venv_activate="$HOME/venv/bin/activate"
    local marker_start="# >>> aicli-venv >>>"
    local marker_end="# <<< aicli-venv <<<"
    local tmp

    [[ -f "$venv_activate" ]] || return 0
    [[ -f "$bashrc" ]] || return 0

    tmp="$(mktemp)"

    awk -v start="$marker_start" -v end="$marker_end" '
        $0 == start { in_block=1; next }
        in_block && $0 == end { in_block=0; next }
        !in_block { print }
    ' "$bashrc" > "$tmp"

    cat >> "$tmp" <<EOF

$marker_start
if [ -f "$HOME/venv/bin/activate" ] && [ -z "\${VIRTUAL_ENV:-}" ]; then
  . "$HOME/venv/bin/activate"
fi
$marker_end
EOF

    if ! cmp -s "$tmp" "$bashrc"; then
        cp "$tmp" "$bashrc"
    fi
    rm -f "$tmp"
}

ensure_harness_path_in_bashrc() {
    local bashrc="$HOME/.bashrc"
    local marker_start="# >>> aih-path >>>"
    local marker_end="# <<< aih-path <<<"
    local tmp

    [[ -f "$bashrc" ]] || return 0

    tmp="$(mktemp)"

    awk -v start="$marker_start" -v end="$marker_end" '
        $0 == start { in_block=1; next }
        in_block && $0 == end { in_block=0; next }
        !in_block { print }
    ' "$bashrc" > "$tmp"

    cat >> "$tmp" <<'EOF'

# >>> aih-path >>>
export PATH="$HOME/.local/bin:$HOME/.ai/bin:$HOME/.ai/tools/bin:$PATH"
# <<< aih-path <<<
EOF

    if ! cmp -s "$tmp" "$bashrc"; then
        cp "$tmp" "$bashrc"
    fi
    rm -f "$tmp"
}

ensure_zvec_env_in_bashrc() {
    local bashrc="$HOME/.bashrc"
    local marker_start="# >>> zvec-memory >>>"
    local marker_end="# <<< zvec-memory <<<"
    local tmp

    [[ -f "$bashrc" ]] || return 0

    tmp="$(mktemp)"

    awk -v start="$marker_start" -v end="$marker_end" '
        $0 == start { in_block=1; next }
        in_block && $0 == end { in_block=0; next }
        !in_block { print }
    ' "$bashrc" > "$tmp"

    cat >> "$tmp" <<'EOF'

# >>> zvec-memory >>>
export ZVEC_MEMORY_PATH="${ZVEC_MEMORY_PATH:-$HOME/.ai/memory/zvec}"
# <<< zvec-memory <<<
EOF

    if ! cmp -s "$tmp" "$bashrc"; then
        cp "$tmp" "$bashrc"
    fi
    rm -f "$tmp"
}

mkdir -p "$AI_HOME" "$HOME/.claude" "$HOME/.codex" "$HOME/.cursor/rules" "$HOME/.gemini"

ensure_venv_activation_in_bashrc
ensure_harness_path_in_bashrc
ensure_zvec_env_in_bashrc

if [[ -f "$HARNESS_ROOT/setup.sh" ]]; then
    (
        cd "$HARNESS_ROOT"
        bash ./setup.sh
        bash ./setup.sh clients
    )
fi

exec "$@"
