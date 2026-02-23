# Agents

Agent definitions live in `definitions/<agent-id>.md`.

Each definition must include YAML frontmatter at the top.

Schema source of truth:

- `schema/agent.frontmatter.yaml`

Validation rules enforced by `scripts/setup/agents.sh`:

- Required frontmatter keys: `id`, `name`, `purpose`, `model`, `skills`, `tools`
- `id` must match the markdown filename
