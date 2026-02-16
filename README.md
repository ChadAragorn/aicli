# AI CLI Sandbox

A containerized development environment for safely running multiple AI CLI tools with persistent configuration and isolated networking.

## Overview

AI CLI Sandbox provides a Docker-based sandbox environment designed to run various AI CLI tools (Claude Code, OpenAI Codex, Google Gemini, and Cursor) in a unified, isolated container. This setup enables you to experiment with different AI tools while maintaining a consistent development environment, complete with all necessary build tools, Node.js ecosystem tools, and version control capabilities.

## Purpose & Use Cases

- **Multi-Tool AI Development**: Work with multiple AI CLI tools in a single container without cluttering your host system
- **Isolated Experimentation**: Test AI tools in a sandboxed environment with controlled access to your system resources
- **Persistent Configuration**: Maintain separate configurations for each AI tool via Docker volumes
- **Safe Automation**: Execute AI CLI commands with predefined security settings via aliases
- **Development Environment**: Pre-configured with Node.js, npm, pnpm, bun, git, and other essential development tools

## Features

- **Multiple AI CLI Tools**: Pre-installed and configured for:
  - Claude Code (Anthropic)
  - OpenAI Codex
  - Google Gemini
  - Cursor
- **Development Toolchain**:
  - Node.js 24 (via nvm)
  - pnpm package manager
  - Bun runtime
  - Git & GitHub CLI
  - SQLite database
  - Python 3
  - Build essentials
- **Security Features**:
  - Isolated `ai` user (uid/gid 10000)
  - Network isolation with optional NET_ADMIN/NET_RAW capabilities
  - Volume mounting for configuration persistence
  - SSH key isolation
- **Developer-Friendly Aliases**: Pre-configured shortcuts for launching AI tools with sensible defaults

## Prerequisites

- Docker and Docker Compose installed
- Git (for cloning this repository)
- SSH keys for git authentication (optional, but recommended)
- Base64 encoding support (for git config injection)

## Installation

### 1. Build the Docker Image

Build the image with your timezone and git configuration:

```bash
docker build --build-arg TZ="America/Denver" --build-arg GITCONFIG=$(base64 -i ~/.gitconfig) -t sandbox .
```

**Build Arguments:**
- `TZ`: Timezone setting (default: `America/Denver`). Use any valid timezone from `/usr/share/zoneinfo/`
- `GITCONFIG`: Optional. Your base64-encoded git config file. Omit to skip git config injection

### 2. Create a Shell Function

Add this function to your `~/.profile` or `~/.bashrc` to easily launch the sandbox:

```bash
# Function to start multi AI CLI capable Docker container
sandbox() {
  docker network create sandbox >/dev/null 2>&1 || true

  docker run --rm -it \
    --network sandbox \
    --cap-add=NET_ADMIN \
    --cap-add=NET_RAW \
    -v "claude:/home/ai/.claude" \
    -v "codex:/home/ai/.codex" \
    -v "cursor:/home/ai/.cursor" \
    -v "gemini:/home/ai/.gemini" \
    -v "ai:/home/ai/.ai" \
    -v "$HOME/.ssh/ai_ed25519:/home/ai/.ssh/id_ed25519:ro" \
    -v "$HOME/.ssh/ai_ed25519.pub:/home/ai/.ssh/id_ed25519.pub:ro" \
    -v "$HOME/.ssh/known_hosts:/home/ai/.ssh/known_hosts:ro" \
    -v "$(pwd):/workspace" \
    -v "$(pwd)/qmd:/home/ai/.cache/qmd" \
    --workdir /workspace \
    sandbox \
    /bin/bash
}
```

Then reload your shell:
```bash
source ~/.profile
```

## Usage

### Launching the Sandbox

```bash
sandbox
```

This command:
- Creates a Docker network named `sandbox` (if it doesn't exist)
- Mounts your SSH keys as read-only volumes
- Shares your current working directory as `/workspace`
- Provides persistent volumes for each AI tool's configuration
- Grants network admin capabilities for firewall/network configuration

### Inside the Sandbox

Once inside, you have access to:

- **AI Tools**: `claude`, `codex`, `cursor`, `gemini` (with pre-configured aliases)
- **Package Managers**: `npm`, `pnpm`, `bun`
- **Development Tools**: `git`, `gh` (GitHub CLI), `python3`, `vim`, `jq`, `ripgrep`
- **Workspace**: Your current directory mounted at `/workspace`

### Example Commands

```bash
# Start development work in your project
sandbox
cd /workspace
git status

# Use Claude Code
claude --help

# Run Node.js scripts
bun run script.js

# Use package managers
pnpm install
npm test
```

## Configuration

### Volume Mounts

The sandbox function mounts several Docker volumes for persistent storage:

| Volume | Purpose |
|--------|---------|
| `claude` | Claude Code configuration and cache |
| `codex` | Codex CLI configuration |
| `cursor` | Cursor editor configuration |
| `gemini` | Gemini CLI configuration |
| `ai` | General AI configuration and memory |

### SSH Keys

The setup expects SSH keys at:
- `~/.ssh/ai_ed25519` (private key, read-only)
- `~/.ssh/ai_ed25519.pub` (public key, read-only)
- `~/.ssh/known_hosts` (known hosts, read-only)

Replace `ai_ed25519` with your actual SSH key name if different.

### Sudo Access & Password

The `ai` user is configured with sudo privileges. The Dockerfile sets a specific password hash for the `ai` user account. You can change this to your own password:

1. Generate a SHA-512 password hash (using `crypt` format with `$y$` prefix):
   ```bash
   python3 -c "import crypt; print(crypt.crypt('your_password', crypt.METHOD_SHA512))"
   ```

2. Replace the hash in the Dockerfile (line 41):
   ```dockerfile
   sed -i 's|^ai:[^:]*:|ai:YOUR_NEW_HASH_HERE:|' /etc/shadow
   ```

3. Rebuild the image with your new hash.

### Customization

To customize the environment:
- Modify the `sandbox()` function to add additional volume mounts or environment variables
- Edit the Dockerfile to install additional tools or change Node.js versions
- Adjust aliases in the Dockerfile for different CLI tool flags
- Update the sudo password (see "Sudo Access & Password" section above)

## Advanced Options

### Custom Timezone

Build with a different timezone:
```bash
docker build --build-arg TZ="America/New_York" -t sandbox .
```

### Network Configuration

The `--cap-add=NET_ADMIN` and `--cap-add=NET_RAW` flags enable advanced networking:
- Network configuration (`iproute2`, `ipset`, `iptables`)
- Firewall rule management via the `init-firewall.sh` script
- Remove these flags if you don't need network admin capabilities

### Custom Working Directory

Mount a different directory:
```bash
docker run --rm -it -v "/path/to/project:/workspace" sandbox /bin/bash
```

## Troubleshooting

- **SSH key errors**: Ensure your SSH key path matches the one in the sandbox function
- **Package installation failures**: The container may need more disk space; increase Docker's allocated storage
- **Network issues**: Remove `--cap-add=NET_ADMIN` and `--cap-add=NET_RAW` if experiencing connectivity problems
- **Volume permission errors**: Check that your host user has read permissions for mounted files

## License

See LICENSE file for details.
