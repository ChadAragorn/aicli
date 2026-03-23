# Tools Contract

## Purpose

Define shared tool discovery and usage policy.

## Source Of Truth

- Executables: `~/.ai/tools/bin/*`
- Public command surface: `~/.ai/bin/*`

## Available Tools

### `wt <number_of_versions>`
Creates N parallel worktree copies of the current repo under `.worktree/v1`, `.worktree/v2`, etc. Each copy gets its own branch (`v1`, `v2`, ...). Also ensures `.worktree/` is in `.gitignore`.

Use this when you need to run multiple independent versions of work in parallel (e.g. A/B testing implementations, parallel agent runs).

```bash
wt 3     # creates .worktree/v1, .worktree/v2, .worktree/v3
wt --rm  # removes the entire .worktree/ directory
```

## Loading Guidance

Load this contract when:
- selecting tools for a task
- evaluating permissions or tool boundaries
- troubleshooting tool availability
