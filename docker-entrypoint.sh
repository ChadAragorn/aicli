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

# Copy configs from image defaults into named volumes (only if they don't exist)
init_config "/home/ai/.claude/settings.json" "/etc/ai/configs/claude/settings.json"
init_config "/home/ai/.codex/AGENTS.md" "/etc/ai/configs/codex/AGENTS.md"
init_config "/home/ai/.cursor/rules/ai-memory-policy.mdc" "/etc/ai/configs/cursor/ai-memory-policy.mdc"
init_config "/home/ai/.gemini/settings.json" "/etc/ai/configs/gemini/settings.json"

# Copy shared directory from image defaults into named volume
init_directory "/home/ai/.ai" "/etc/ai/shared"

# Execute the command passed to the container
exec "$@"
