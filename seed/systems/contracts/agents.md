# Agents Contract

## Purpose

Define how agents are represented and selected in the harness.

## Source Of Truth

- Agent definitions: `~/.ai/agents/definitions/*.md`
- Required frontmatter keys: `id`, `name`, `purpose`, `model`, `skills`, `tools`

## Loading Guidance

Load this contract when:
- choosing or delegating to agents
- validating agent definitions
- resolving authority between overseer and specialists
