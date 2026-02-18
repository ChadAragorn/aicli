#!/bin/bash
set -e

# Initialize config files if they're empty (copy from image defaults)
init_config() {
    local dest_dir="$1"
    local source_file="$2"

    if [ -f "$source_file" ]; then
        mkdir -p "$(dirname "$dest_dir")"
        if [ ! -f "$dest_dir" ]; then
            cp "$source_file" "$dest_dir"
            echo "Initialized $dest_dir from $source_file"
        fi
    fi
}

# Initialize config directories if they're empty (copy from image defaults)
init_directory() {
    local dest_dir="$1"
    local source_dir="$2"

    if [ -d "$source_dir" ]; then
        mkdir -p "$dest_dir"
        if [ ! -d "$dest_dir" ] || [ -z "$(ls -A "$dest_dir")" ]; then
            cp -r "$source_dir"/* "$dest_dir/"
            echo "Initialized $dest_dir from $source_dir"
        fi
    fi
}

# Ensure shell sessions activate the project venv automatically.
ensure_venv_activation_in_bashrc() {
    local bashrc="/home/ai/.bashrc"
    local venv_activate="/home/ai/venv/bin/activate"
    local marker_start="# >>> aicli-venv >>>"
    local marker_end="# <<< aicli-venv <<<"
    local tmp

    [ -f "$venv_activate" ] || return 0
    [ -f "$bashrc" ] || return 0

    tmp="$(mktemp)"

    # Remove any existing managed block, then append one canonical block.
    awk -v start="$marker_start" -v end="$marker_end" '
        $0 == start { in_block=1; next }
        in_block && $0 == end { in_block=0; next }
        !in_block { print }
    ' "$bashrc" > "$tmp"

    cat >> "$tmp" <<EOF

$marker_start
if [ -f "/home/ai/venv/bin/activate" ] && [ -z "\${VIRTUAL_ENV:-}" ]; then
  . "/home/ai/venv/bin/activate"
fi
$marker_end
EOF

    if ! cmp -s "$tmp" "$bashrc"; then
        cp "$tmp" "$bashrc"
    fi
    rm -f "$tmp"
}

# Copy configs from image defaults into named volumes (only if they don't exist)
init_config "/home/ai/.claude/settings.json" "/etc/ai/configs/claude/settings.json"
init_config "/home/ai/.codex/AGENTS.md" "/etc/ai/configs/codex/AGENTS.md"
init_config "/home/ai/.cursor/rules/ai-memory-policy.mdc" "/etc/ai/configs/cursor/ai-memory-policy.mdc"
init_config "/home/ai/.gemini/settings.json" "/etc/ai/configs/gemini/settings.json"

# Copy shared directory from image defaults into named volume
init_directory "/home/ai/.ai" "/etc/ai/shared"

# Ensure interactive shells source venv activation from .bashrc
ensure_venv_activation_in_bashrc

# Execute the command passed to the container
exec "$@"
