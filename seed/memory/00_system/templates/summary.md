---
id: "{{ id }}"
type: session
project: "{{ project }}"
ai: "{{ ai | default('unknown') }}"
agent: "{{ agent | default('') }}"
created: "{{ created }}"
updated: "{{ updated }}"
status: "{{ status | default('active') }}"
tags: {{ tags | default(['memory', 'summary']) }}
topics: {{ topics | default([]) }}
links: {{ links | default([]) }}
source: conversation
confidence: "{{ confidence | default('medium') }}"
transcript: "{{ transcript | default('unknown') }}"
---

# {{ title | default('session summary') }}

## Summary
{{ summary | default('') }}

## Key Decisions
{% for item in key_decisions | default([]) %}
- {{ item }}
{% endfor %}

## Work Completed
{% for item in work_completed | default([]) %}
- {{ item }}
{% endfor %}

## Open Questions
{% for item in open_questions | default([]) %}
- {{ item }}
{% endfor %}

## Next Actions
{% for item in next_actions | default([]) %}
- {{ item }}
{% endfor %}

## References
{% for item in references | default([]) %}
- [[{{ item }}]]
{% endfor %}
