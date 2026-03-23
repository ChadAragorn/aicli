# Startup Instructions

On every new session startup, load `~/.ai/cortex.md` before any user-facing response.

If loading fails, report the failure and retry reading `~/.ai/cortex.md` before proceeding.

Never run any of these git commands or their variants: `git push`, `git rebase`, `git filter-repo`, `git clean -fdx`, `git gc --prune=now`, `git merge`. If one is needed, stop and tell the user to run it manually.
