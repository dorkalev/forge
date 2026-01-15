---
description: List all available commands
---

# /help - Available Commands

## Check for Updates First

Before showing help, check if there's a newer version:

```bash
# Get remote version from GitHub
REMOTE_VERSION=$(curl -s https://raw.githubusercontent.com/dorkalev/forge/main/.claude-plugin/plugin.json | grep '"version"' | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/')

# Get local version (from plugin installation path or default)
LOCAL_VERSION="1.2.0"

if [ "$REMOTE_VERSION" != "$LOCAL_VERSION" ]; then
  echo "⚠️  UPDATE AVAILABLE: forge $REMOTE_VERSION (you have $LOCAL_VERSION)"
  echo "   Run: /plugin update forge@dorkalev/forge"
  echo ""
fi
```

If an update is available, show the notice BEFORE the command list.

## Command Reference

Output the following:

```
═══════════════════════════════════════════════════════════════════════════
                           MAIN WORKFLOW
═══════════════════════════════════════════════════════════════════════════

  1. /forge:issues    Pick a ticket or create one → opens new worktree + tmux
  2. (you code...)
  3. /forge:finish    Push, PR ready, CodeRabbit review, auto-fix
  4. (PR merged...)
  5. /forge:cleanup   Remove worktree, delete branches, close tmux

That's it. Most of the time you only need these 3 commands.

═══════════════════════════════════════════════════════════════════════════
                         UTILITY COMMANDS
═══════════════════════════════════════════════════════════════════════════

These are for specific situations, not the main workflow:

/forge:new-issue <desc>   Quick: create ticket from description, skip browsing
/forge:ticketify          After planning chat, turn discussion into a ticket
/forge:ticket <id>        Load a ticket into current session (no new worktree)
/forge:worktree           Create worktree for existing branch (no new ticket)
/forge:pr                 Open PR page in browser
/forge:audit              Preview what /forge:finish will find (read-only)
/forge:fix-pr             Manually trigger CodeRabbit fix loop

/forge:help               Show this message
```
