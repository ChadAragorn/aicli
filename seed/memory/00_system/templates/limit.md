---
id: "{{ id }}"
type: context
project: "{{ project }}"
ai: "{{ ai | default('unknown') }}"
agent: "{{ agent | default('') }}"
created: "{{ created }}"
updated: "{{ updated }}"
status: "{{ status | default('active') }}"
tags: {{ tags | default(['memory', 'checkpoint', 'context']) }}
topics: {{ topics | default(['continuation']) }}
links: {{ links | default([]) }}
source: conversation
confidence: "{{ confidence | default('medium') }}"
transcript: "{{ transcript | default('unknown') }}"
---

# {{ title | default('85 percent context checkpoint') }}

## Trigger
{{ trigger | default('context usage reached approximately 85%') }}

## Current Objective
{{ current_objective | default('') }}

## State Snapshot
- branch: {{ branch | default('') }}
- latest commit: {{ latest_commit | default('') }}
- working tree: {{ working_tree | default('') }}
- key files changed:
{% for item in key_files_changed | default([]) %}
  - {{ item }}
{% endfor %}

## Decisions To Preserve
{% for item in decisions_to_preserve | default([]) %}
- {{ item }}
{% endfor %}

## Risks And Constraints
{% for item in risks_and_constraints | default([]) %}
- {{ item }}
{% endfor %}

## Resume Plan
{% for item in resume_plan | default([]) %}
{{ loop.index }}. {{ item }}
{% endfor %}

## References
{% for item in references | default([]) %}
- [[{{ item }}]]
{% endfor %}
