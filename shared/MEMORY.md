# 🌍 Global Memory System

This file is your persistent memory across all sessions. It defines:
- How sessions start and manage context
- User preferences and development patterns
- Security constraints and best practices
- Lessons learned and architectural decisions

---

## Session Start Contract

This file must be loaded at the start of every new session before any user-facing answer.

Required startup order:
1. Read `~/.ai/MEMORY.md`.
2. Apply user preferences from this file.
3. Proceed with task work.

If step 1 fails, the assistant should report the failure and retry before continuing.

## Memory File Structure (Canonical)

All memory files written to `~/.ai/memory/YYYY-MM-DD-HHMMSS.md` must use this structure:

```markdown
# Session: YYYY-MM-DD-HHMMSS
# Project: PROJECT-NAME
# Model: ACTIVE-MODEL

## Context Checkpoint

### Summary
[Brief summary of conversation so far]

### Key Accomplishments
- [What was completed]
- [Decisions made]
- [Code written]

### Decisions Made
- [Decision]

### Code Written/Modified
- [File or change]

### Lessons Learned
- [Important insights]
- [Mistakes and solutions]

### Current State/Next Steps
- [What's in progress]
- [Next steps]
```

**Project**: Obtain the value for `# Project:` by running `mem project`. It uses the git remote URL (from any subdirectory) with `.git` stripped and trimmed, or the current directory basename if not in a git repo.

**Timestamp**: Obtain date and time from the system when creating memory file names and the `# Session:` header. Do not use user_info "Today's date" or any other non-system source—they can be wrong (e.g. year or timezone). Use the mem skill:
- `mem timestamp` — session/filename: YYYY-MM-DD-HHMMSS
- `mem timestamp iso` — heartbeat `lastCheckpoint`: ISO format

## Heartbeat State Structure (Canonical)

Heartbeat state at `~/.ai/memory/heartbeat-state.json` should use this minimal structure:

```json
{
  "lastCheckpoint": "YYYY-MM-DDTHH:MM:SS",
  "lastSession": "YYYY-MM-DD-HHMMSS",
  "lastTrigger": "threshold|summary|sessionEnd"
}
```

## 🚨 Auto-Checkpoint Instructions

**CRITICAL**: When context window utilization reaches 85% (15% remaining):

1. **Check context usage** from system warnings (format: `Token usage: X/Y; Z remaining`)
2. **Calculate**: If `(tokens_used / total_budget) >= 0.85`, trigger checkpoint
3. **Determine project name** with `mem project`
4. **Determine timestamp** with `mem timestamp` (and `mem timestamp iso` for heartbeat)
5. **Create checkpoint** by writing to `~/.ai/memory/$(mem timestamp).md` using the **Memory File Structure (Canonical)** section above.
6. **Update heartbeat state** by writing to `~/.ai/memory/heartbeat-state.json` using the **Heartbeat State Structure (Canonical)** section above with `lastTrigger` set to `threshold`.
7. **Notify user**: "⚠️  Context checkpoint created at 85% (saved to ~/.ai/memory/YYYY-MM-DD-HHMMSS.md)"
8. **Continue working** - no need to restart session unless context is critically full

This prevents losing work when approaching model context limits (works with any model: Opus/Sonnet/Haiku, any context window size).

**Project-specific search**: Session files include `# Project: NAME` header for targeted retrieval (e.g., `mem search "Project: claude-code"`).

## Manual Summary Trigger

If the user sends exactly the single word `summary`, treat it as an immediate save command.

Required behavior:
1. **Determine project name** with `mem project`
2. **Determine timestamp** with `mem timestamp` (and `mem timestamp iso` for heartbeat)
3. Summarize current conversation context into memory format.
4. Write a new file at `~/.ai/memory/$(mem timestamp).md`.
5. Use the **Memory File Structure (Canonical)** section above.
6. **Update heartbeat state** by writing to `~/.ai/memory/heartbeat-state.json` using the **Heartbeat State Structure (Canonical)** section above with `lastTrigger` set to `summary`.
7. Confirm to user that summary memory was created with the saved file path.

## User Preferences

## Development Patterns
- **Use rg (ripgrep)** when you need to search files - it's faster and more powerful than grep
- **Use mem tool** (mem search "query") when user asks to search memories or look up past interactions

## Lessons Learned

## Security Constraints
- Never access any `.env.*` file by any method (AI file tools or shell commands such as `cat`, `grep`, `rg`, `find`, etc.).
- The only allowed exceptions are `.env.local` and `.env.example`.
