# AI Memory

## Session Start Contract

This file must be loaded at the start of every new session before any user-facing answer.

Required startup order:
1. Read `~/.ai/MEMORY.md`.
2. Apply user preferences from this file.
3. Proceed with task work.

If step 1 fails, the assistant should report the failure and retry before continuing.

## 🚨 Auto-Checkpoint Instructions

**CRITICAL**: When context window utilization reaches 85% (15% remaining):

1. **Check context usage** from system warnings (format: `Token usage: X/Y; Z remaining`)
2. **Calculate**: If `(tokens_used / total_budget) >= 0.85`, trigger checkpoint
3. **Determine project name** from primary working directory (basename of the path)
4. **Create checkpoint** by writing to `~/.ai/memory/YYYY-MM-DD-HHMM.md`:
   ```markdown
  # Session: YYYY-MM-DD-HHMM
  # Project: PROJECT-NAME
  # CLI: (cursor, opencode, claude-code, etc...)
  # Model: (gpt-5, claude-sonnet, gemini, etc...)

   ## Context Checkpoint (85% utilization)

   ### Summary
   [Brief summary of conversation so far]

   ### Key Accomplishments
   - [What was completed]
   - [Decisions made]
   - [Code written]

   ### Lessons Learned
   - [Important insights]
   - [Mistakes and solutions]

   ### Current State
   - [What's in progress]
   - [Next steps]
   ```
5. **Notify user**: "⚠️  Context checkpoint created at 85% (saved to ~/.ai/memory/YYYY-MM-DD-HHMM.md)"
6. **Continue working** - no need to restart session unless context is critically full

This prevents losing work when approaching model context limits (works with any model: Opus/Sonnet/Haiku, any context window size).

**Project-specific search**: Session files include `# Project: NAME` header for targeted retrieval (e.g., `mem search "Project: claude-code"`).

## User Preferences

## Development Patterns
- **Use rg (ripgrep)** when you need to search files - it's faster and more powerful than grep
- **Use mem tool** (mem search "query") when user asks to search memories or look up past interactions

## Lessons Learned

## Security Constraints
- Never access any `.env.*` file by any method (AI file tools or shell commands such as `cat`, `grep`, `rg`, `find`, etc.).
- The only allowed exceptions are `.env.local` and `.env.example`.
