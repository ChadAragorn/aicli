# AI Foundation Global Harness

This repository defines a local, AI-agnostic harness so different AI TUIs
(Claude, Codex, Gemini, etc.) can operate against the same system.

## Scope

- shared tools
- agent definitions
- shared memory vault
- system prompts/contracts
- infrastructure hooks/scripts

## Layout

- `seed/bin/aih`: Harness CLI source for initializing and validating shared state.
- `seed/tools/bin/vault`: Canonical memory vault CLI (file-native markdown+YAML notes).
- `setup.sh`: Root bootstrap orchestrator for new-system provisioning.
- `scripts/setup/*.sh`: Per-domain installers (`plugins.sh`, `agents.sh`, etc.).
- `seed/`: Repository seed bundle copied into `$AI_HOME` during setup.
- `docs/architecture.md`: Canonical architecture and integration contract.

Bootstrap contract:

- `~/.ai/cortex.md` is loaded first at session start.
- contracts are loaded lazily from `~/.ai/systems/contracts/*.md` as needed.

## Quick Start

```bash
./setup.sh
~/.ai/bin/aih status
~/.ai/bin/aih agents lint
vault init
vault status
vault archive path/to/note.md
```

Component bootstrap examples:

```bash
AI_HOME=/tmp/global ./setup.sh core memory tools skills plugins agents systems infra bin
./setup.sh clients
```

Agent definitions are stored in `seed/agents/definitions/*.md` with YAML
frontmatter and are validated during `setup.sh agents` against required fields
and filename/id match.

## Install Commands

```bash
./setup.sh
```

This installs:

- `~/.ai/bin/aih` (harness CLI)

During setup, shared harness executables are also installed into `~/.ai/bin`
(or `$AI_HOME/bin`) so any AI TUI can invoke a common command surface.

Add both `~/.ai/tools/bin` and `~/.ai/bin` to your PATH so `vault`, `mem`,
`docslug`, `transcriptid`, `zmem`, and `aih` are directly invocable.

```bash
export PATH="$HOME/.ai/tools/bin:$HOME/.ai/bin:$PATH"
```

## Semantic Memory (zvec-memory)

This harness keeps markdown notes as canonical memory (`vault`) and supports
`zvec-memory` as a semantic retrieval layer.

Default vector memory path:

```bash
export ZVEC_MEMORY_PATH="$HOME/.ai/memory/zvec"
```

Use wrapper commands:

```bash
zmem init
zmem add "Important project decision: use harness-first bootstrap."
zmem search "bootstrap contract"
zmem stats
```

## Shared Documentation Vault

Project documentation is expected to live in a separate Obsidian vault repo.

Set `DOC_VAULT_ROOT` to your local documentation vault path:

```bash
export DOC_VAULT_ROOT="/path/to/your/documentation/vault"
```

`DOC_VAULT_ROOT` is the global documentation vault location. It is separate from the
project repo you are actively working in.
Project documentation folder names are determined by running `docslug` in the working
project repo. Documentation generation should fail if either `DOC_VAULT_ROOT` is unset
or `docslug` is unavailable.

Add that export to your shell startup file (`~/.bashrc`, `~/.zshrc`, or `~/.profile`) so tooling can consistently find the shared docs vault.

## Container Workflow

### Prerequisites

- Docker installed and available in your shell
- New SSH keys created specifically for AI use `ssh-keygen -oa 1000 -t ed25519 -f ~/.ssh/ai_ed25519
- Optional: base64 support if passing `GITCONFIG` at build time

### Build Image

```bash
docker build \
  --build-arg TZ="America/Denver" \
  --build-arg GITCONFIG="$(base64 -w 0 ~/.gitconfig 2>/dev/null || base64 ~/.gitconfig | tr -d '\n')" \
  -t sandbox .
```

Notes:

- `TZ` controls container timezone.
- `GITCONFIG` is optional; omit it if you do not want to inject git config.

### Run Container

Add this helper to `~/.bashrc`, `~/.zshrc`, or `~/.profile`:

```bash
sandbox() {
  docker network create sandbox >/dev/null 2>&1 || true

  docker run --rm -it \
    --network sandbox \
    -v "claude:/home/ai/.claude" \
    -v "codex:/home/ai/.codex" \
    -v "cursor:/home/ai/.cursor" \
    -v "gemini:/home/ai/.gemini" \
    -v "ai:/home/ai/.ai" \
    -v "$HOME/.ssh/ai_ed25519:/home/ai/.ssh/id_ed25519:ro" \
    -v "$HOME/.ssh/ai_ed25519.pub:/home/ai/.ssh/id_ed25519.pub:ro" \
    -v "$HOME/.ssh/known_hosts:/home/ai/.ssh/known_hosts:ro" \
    -v "$(pwd):/workspace" \
    --workdir /workspace \
    sandbox \
    /bin/bash
}
```

On startup, the container entrypoint runs harness setup and client config merge:

- `setup.sh` (default components)
- `setup.sh clients`

### Security Note

The default CLI functions configured in the image use permissive flags (`--yolo`,
`--dangerously-*`). Treat this container as an untrusted automation environment,
not a hardened production boundary.

### Shell Launch Functions

These are the shell functions to launch the various tui:

```bash
agent() { TID="$(openssl rand -hex 24)" PROVIDER=cursor command agent --yolo "$@"; }
claude() { TID="$(openssl rand -hex 24)" PROVIDER=claude command claude --dangerously-skip-permissions "$@"; }
codex() { TID="$(openssl rand -hex 24)" PROVIDER=codex command codex --dangerously-bypass-approvals-and-sandbox "$@"; }
gemini() { TID="$(openssl rand -hex 24)" PROVIDER=gemini command gemini --yolo "$@"; }
```
