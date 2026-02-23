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

Use `zvec-memory` as a supplemental semantic retrieval layer alongside vault notes.

- Keep canonical durable records in vault notes under `~/.ai/memory`.
- Use vector memory for fast similarity lookup, not as the primary source of truth.
- Default vector store path: `~/.ai/memory/zvec` (via `ZVEC_MEMORY_PATH`).
- Prefer `zmem` wrapper (`~/.ai/tools/bin/zmem`) for consistent path/config handling.

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
- Avoid duplicating notes across project and inbox paths.
- Use `rg` for retrieval over full-vault scans when possible.

## Security Constraints

- Never access any `.env.*` file by any method (AI file tools or shell commands such as `cat`, `grep`, `rg`, `find`, etc.).
- The only allowed exceptions are `.env.local` and `.env.example`.
