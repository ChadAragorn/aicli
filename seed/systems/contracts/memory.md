# Memory Contract

This contract defines how durable memory is written and organized in the
AI-agnostic harness.

## Session Start Contract

This file is loaded on-demand via `~/.ai/cortex.md` when memory behavior is
required.

## Canonical Writer

Use `vault` as the canonical memory writer.

- Ensure `~/.ai/tools/bin` is on PATH for direct `vault` invocation.
- Invoke as `vault` rather than absolute tool paths.

## Semantic Memory Layer

Use `engram` as the supplemental memory retrieval layer alongside vault notes.

- Keep canonical durable records in vault notes under `~/.ai/memory`.
- Use engram for session summaries and fast full-text search across past sessions.
- Default engram data path: `~/.ai/memory/engram` (via `ENGRAM_DATA_DIR`).
- Engram is available as an MCP server (`engram mcp`) and CLI (`engram search`, `engram tui`).

## Canonical Memory Location

Memory notes are stored under:

- `~/.ai/memory`

Vault structure is file-native markdown with YAML frontmatter.

## Metadata Rules

- `project` metadata should use `docslug` output.
- `ai` metadata should use `PROVIDER` (use `unknown` when unset).
- `created` and `updated` timestamps should use local time.
- `id` should be stable and timestamp-derived.
- `transcript` should exist in frontmatter; use `unknown` when unresolved.

## Operational State

- Heartbeat state remains part of memory automation, not vault note authoring.
- Heartbeat file location: `~/.ai/memory/heartbeat-state.json`
- On each successful `vault new`, heartbeat should update with:
  - `lastCheckpoint`
  - `lastSession`
  - `lastTrigger` (`vault_new`)
  - `lastMemoryPath` (absolute path of the latest created memory note)

## Note Types

Supported canonical memory note types:

- `session`
- `decision`
- `context`
- `task`
- `entity`
- `daily`
- `inbox`
- `moc`

## Transcript Metadata

When transcript linkage is needed:

- include transcript path metadata in the note body or frontmatter
- use `transcriptid` with `PROVIDER` and `TID` to resolve provider transcript files
- write `unknown` rather than guessing when resolution is ambiguous

## Operational Guidance

- Prefer creating concise notes early, then refining.
- When using `vault new`, keep titles date-free (no explicit date/timestamp text); filenames are already timestamp-prefixed by `vault`.
- Avoid duplicating notes across project and inbox paths.
- Use `rg` for retrieval over full-vault scans when possible.

## Security Constraints

- Never access any `.env.*` file by any method (AI file tools or shell commands such as `cat`, `grep`, `rg`, `find`, etc.).
- The only allowed exceptions are `.env.local` and `.env.example`.
