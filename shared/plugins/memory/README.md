# Memory Plugin

A comprehensive memory system for AI that implements persistent, cross-project memory with session files, checkpoints, and curated long-term knowledge.

## Overview

This plugin implements a **search-based memory system** with automatic checkpointing:

```
Session Context (ephemeral)
    ↓ [Auto-checkpoint at 85% context OR manual save]
Session Files (mid-term, searchable)
    ↓ [Manual curation]
MEMORY.md (long-term, curated)
```

**Key principle**: Session files are searched on-demand, not loaded automatically.

## Architecture

### 1. Short-Term Memory: Session Context

- Active conversation in current session
- Up to 200k tokens of working memory
- Disappears when session ends

### 2. Mid-Term Memory: Session Files

**Location**: `~/.ai/memory/YYYY-MM-DD-HHMM.md` (timestamped per session)

Session files are created two ways:

#### A) **Auto-checkpoint** (at 85% context utilization)
AI automatically creates a checkpoint when context window reaches 85% full. The checkpoint includes:
- Summary of conversation
- Key accomplishments and decisions
- Code changes and lessons learned
- Current task state

#### B) **Manual save** (ask anytime)
Simply ask: "Save this session" or "Create a checkpoint"

**Not loaded automatically** - Session files are searched on-demand using `mem search` or rg when you need specific context.

**Retention**: Keep as long as useful, archive old sessions manually

**Example format**:
```markdown
# Session: 2026-02-16-1430
# Project: PROJECT-NAME
# CLI: (agent, claude, gemini, codex, etc...)
# Model: (sonnet, minimax-m2.5, etc ...)

## Context Checkpoint (85% utilization)

### Summary
Built memory plugin for AI with auto-checkpoint system

### Key Accomplishments
- Implemented SessionStart hook to load MEMORY.md
- Added auto-checkpoint instructions to MEMORY.md
- Removed Stop hook (relies on MEMORY.md instructions instead)

### Lessons Learned
- Stop hooks don't support hookSpecificOutput
- Search-based retrieval is more efficient than auto-loading

### Current State
- Plugin is production-ready
- Testing across multiple sessions
```

### 3. Long-Term Memory: MEMORY.md

**Location**: `~/.ai/MEMORY.md`

Curated knowledge base containing:
- **Auto-checkpoint instructions** (tells AI when to checkpoint)
- User preferences and workflows
- Development patterns to follow
- Lessons learned from mistakes
- Tool stack and conventions

**Critical**: MEMORY.md includes instructions that trigger auto-checkpoint at 85% context utilization (works with any model/context window size)

**Update cadence**: Manual curation from session files every few days

## How It Works

### 1. SessionStart Hook

When a session starts:
- Loads **MEMORY.md** into context (includes auto-checkpoint instructions)
- Session files are NOT loaded automatically

### 2. Auto-Checkpoint (Self-Enforcing)

AI monitors context usage and automatically creates checkpoints:
- **Trigger**: When context reaches 85% utilization (15% remaining)
- **Action**: Creates `~/.ai/memory/YYYY-MM-DD-HHMM.md` with session summary
- **Works with any model**: Sonnet, Opus, Haiku - any context window size
- **Self-enforcing**: Instructions in MEMORY.md, loaded every session

### 3. Manual Save (Anytime)

Ask AI to save the session whenever you want:
```
"Save this session"
"Create a checkpoint of what we've accomplished"
"Dump your context to memory"
```

AI should create a timestamped session file with:
- Summary of conversation
- Key decisions and accomplishments
- Lessons learned
- Current state

### 4. Search-Based Retrieval

Session files are searched on-demand when needed:
```bash
mem search "authentication bug"
mem search "decided to use PostgreSQL"
```

Or use rg:
```
rg [OPTIONS] PATTERN [PATH ...]
```

### Memory Flow

```
┌─────────────────┐
│ Session Context │  (Conversations, loaded files)
└────────┬────────┘
         │ Auto-checkpoint at 85% OR manual "save this session"
         ▼
┌─────────────────┐
│ Session Files   │  ~/.ai/memory/YYYY-MM-DD-HHMM.md
│ (timestamped)   │  ← Search on-demand with 'mem search'
└────────┬────────┘
         │ Manual curation (extract key learnings)
         ▼
┌─────────────────┐
│ MEMORY.md       │  ~/.ai/MEMORY.md (loaded every session)
└─────────────────┘
```

## Installation

The plugin is located at in the ~/.ai/plugins/ directory

### Setup has been completed

1. **Register the hook in `~/.ai/settings.json`**:
   ```json
   {
     "model": "sonnet",
     "hooks": {
       "SessionStart": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "~/.ai/plugins/memory/hooks-handlers/session-start.sh"
             }
           ]
         }
       ]
     }
   }
   ```

2. **Initialize the memory system**:
   ```bash
   plugins/memory/bin/mem init
   ```

   This creates:
   - `~/.ai/MEMORY.md` (long-term memory template with auto-checkpoint instructions)
   - `~/.ai/memory/` (directory for session files)
   - `~/.ai/memory/heartbeat-state.json` (optional state tracking)

3. **Edit your long-term memory**:
   ```bash
   plugins/memory/bin/mem edit memory
   ```

   The default `MEMORY.md` includes auto-checkpoint instructions that trigger at 85% context utilization. Add your preferences, patterns, and learnings.

4. **The plugin will automatically**:
   - Load `MEMORY.md` at session start (includes auto-checkpoint instructions)
   - AI should monitor context and creates checkpoints at 85%
   - You can manually save by asking AI: "Save this session"

## CLI Tool: `mem`

The `mem` command helps you manage your memory system.

### Commands

```bash
# Initialize memory system
mem init

# Check status
mem status

# Create a manual checkpoint
mem checkpoint "Completed feature X"

# Edit files
mem edit memory      # Edit MEMORY.md
mem edit today       # Edit today's session files
mem edit yesterday   # Edit yesterday's notes

# List recent session files
mem list           # Last 30 days
mem list 7         # Last 7 days

# Show help
mem help
```

### Example Workflow

```bash
# Day 1: Setup
$ mem init
✓ Memory system initialized

# During the day: Work with AI
# AI automatically monitors context and checkpoints at 85%
# Or ask AI: "Save this session" anytime

# Search for past context
$ mem search "authentication bug"
$ mem search "Project: claude-code"

# Review recent sessions
$ mem list 10
  2026-02-16-1430 - 45 lines, 3 checkpoints
  2026-02-16-0845 - 32 lines, 2 checkpoints
  ...

# Weekly: Curate learnings into long-term memory
$ mem edit memory
# Extract key learnings from session files
# Add to appropriate sections in MEMORY.md
```

## File Structure

```
~/.ai/
├── MEMORY.md                    # Long-term curated memory (with auto-checkpoint instructions)
└── memory/                      # All memory artifacts
    ├── 2026-02-16-0845.md      # Session file (includes "Project: name" header)
    ├── 2026-02-16-1430.md      # Another session
    └── heartbeat-state.json    # Optional state tracking
```

## What to Store Where

### ✅ MEMORY.md (Long-term)

Good candidates:
- User preferences: "Always use TypeScript over JavaScript"
- Development patterns: "API endpoints follow REST conventions"
- Tool preferences: "Use bun instead of npm"
- Security practices: "Never commit .env files"
- Lessons learned: "Always run tests before committing"

### ✅ Session Files (Mid-term)

Created automatically (at 85% context) or manually (ask AI):
- Session checkpoints (automatic)
- Manual checkpoints: `mem checkpoint "message"`

Add manually:
- Decisions made during the day
- Blockers encountered and solutions
- Architecture discussions
- Tasks completed

### ❌ Avoid Storing

- Project-specific code or file paths (use per-project memory instead)
- Sensitive information (API keys, passwords)
- Large amounts of code
- Outdated information

## Hooks Registration

**`hooks.json`**:
```json
{
  "hooks": {
    "SessionStart": {
      "handler": "./hooks-handlers/session-start.sh"
    }
  }
}
```

## Memory Management Best Practices

### Keep MEMORY.md Concise

- Focus on actionable instructions
- Use clear sections and headers
- Remove outdated information regularly
- Write what you want AI to follow, not everything you know

### Review Daily Notes Weekly

- Read through the week's session files
- Extract significant learnings
- Update MEMORY.md with distilled wisdom
- Remove noise, keep signal

### Manual Checkpoints

Use `mem checkpoint` for important moments:
```bash
mem checkpoint "Decided to use SQLite for local storage"
mem checkpoint "Fixed critical bug in authentication"
mem checkpoint "Architecture review with team"
```

## Future Enhancements

Potential improvements (inspired by OpenClaw):

1. **Search system**: `mem search "query"` using keyword or semantic search
2. **Auto-curation**: Suggest MEMORY.md updates from recent session files
3. **Heartbeat automation**: Context-aware checkpointing during long sessions
4. **Cold storage**: Archive session files >60 days old with compression
5. **Reflection agent**: Periodic summarization of session files

## Troubleshooting

### Plugin not loading

Check if hooks are registered:
```bash
cat plugins/memory/hooks.json
```

### Memory not injecting

1. Verify files exist:
   ```bash
   ls -la ~/.ai/MEMORY.md
   ls -la ~/.ai/memory/
   ```

2. Test hooks manually:
   ```bash
   plugins/memory/hooks-handlers/session-start.sh
   ```

3. Check for `jq` installation:
   ```bash
   which jq || brew install jq
   ```

### Checkpoints not being created

Verify SessionEnd hook is executable:
```bash
chmod +x plugins/memory/hooks-handlers/session-end.sh
```

## Philosophy

**"Memory is limited — if you want to remember something, WRITE IT TO A FILE."**

- Mental notes don't survive session restarts
- Files do
- Daily notes are your raw journal
- MEMORY.md is your curated wisdom

**Text > Brain** 📝

## License

Same as AI repository.
