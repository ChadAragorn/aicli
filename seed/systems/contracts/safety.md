# Safety Contract

## Purpose

Define guardrails for filesystem access and high-risk actions.

## Rules

- Never access any `.env.*` file except `.env.local` and `.env.example`.
- Avoid destructive commands unless explicitly requested and confirmed.
- Prefer non-interactive and reversible operations.

## Loading Guidance

Load this contract when:
- performing potentially destructive actions
- handling secrets or sensitive files
- operating outside normal sandbox constraints
