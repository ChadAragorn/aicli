# AI-Agnostic Harness Architecture

## Goal

Provide one local operating substrate so multiple AI clients/TUIs can share:

- memory
- tools
- agent definitions
- prompt/system contracts

The UI/client is interchangeable; the filesystem contract is stable.

## Canonical Harness Paths

Default root:

```text
~/.ai
```

Canonical directories:

- `~/.ai/bin` - shared executable entrypoints on PATH
- `~/.ai/memory` - persistent memory vault files
- `~/.ai/agents/definitions` - agent profiles/personas/workflows
- `~/.ai/tools/bin` - executable shared tools
- `~/.ai/systems/contracts` - modular harness contracts (memory, agents, tools, safety)
- `~/.ai/systems/prompts` - reusable system prompts/instructions
- `~/.ai/infra/hooks` - lifecycle hooks/integration scripts

## Integration Pattern (Any TUI)

1. On startup, resolve `AI_HOME` or default to `~/.ai`.
2. Load `~/.ai/cortex.md` first, then lazily load `~/.ai/systems/contracts/*.md` by task trigger.
3. Read and write memory through the vault path (`~/.ai/memory` by default).
4. Use shared entrypoints from `~/.ai/bin` and shared tools from `~/.ai/tools/bin`.

## Repository Role

This repo is the source-of-truth and bootstrap layer:

- ships CLI scripts (`seed/bin/aih`, `setup.sh`) and tools (including `seed/tools/bin/vault`)
- defines contract docs
- syncs configs into user environment

State lives in `~/.ai/*`, not in the repo.
