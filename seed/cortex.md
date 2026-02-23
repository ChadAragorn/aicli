# Cortex

This is the top-level bootstrap contract for the AI-agnostic harness.

## Session Start Contract

This file must be loaded at the start of every new session before any user-facing answer.

Required startup order:
1. Read `~/.ai/cortex.md`.
2. Before any user-facing message, mention `TID` and `PROVIDER` values if set.
3. Do not preload all contracts; load only the contracts required by the current task.
4. Proceed with task work.

If step 1 fails, report the failure and retry before continuing.

## Harness Roadmap

Canonical harness paths:

- `~/.ai/bin` - shared command entrypoints
- `~/.ai/agents/definitions` - agent definitions
- `~/.ai/skills` - shared skills
- `~/.ai/tools/bin` - shared tools
- `~/.ai/plugins` - plugin packages
- `~/.ai/memory` - session memory files

## Required Component Contracts

- `~/.ai/systems/contracts/memory.md` - memory policy and checkpoint format
- `~/.ai/systems/contracts/agents.md` - agent selection and delegation contract
- `~/.ai/systems/contracts/tools.md` - shared tools contract
- `~/.ai/systems/contracts/safety.md` - safety and high-risk action contract

## Contract Loading Policy (Context Control)

Load contracts lazily by trigger:

- Load `memory.md` only when memory read/write/checkpoint behavior is needed.
- Load `agents.md` when selecting or delegating agents.
- Load `tools.md` when tool choice/permissions are relevant.
- Load `safety.md` for high-risk, destructive, or sensitive operations.

## Session Correlation (TID)

- If `TID` and `PROVIDER` are present in environment, include `TID=<value>` and `PROVIDER=<value>` before any user-facing content.
- Use `TID` and `PROVIDER` as the primary session correlation keys for transcript lookup and debugging.
- If either `TID` or `PROVIDER` is missing, explicitly state which value is missing and continue.

## Operating Rules

- Treat this file as the harness bootstrap source of truth.
- Use shared tools and skills before creating new local-only logic.
- Keep durable memory in `~/.ai/memory` following `~/.ai/systems/contracts/memory.md`.
- Never access any disallowed secret files (`.env.*` except `.env.local` and `.env.example`).
