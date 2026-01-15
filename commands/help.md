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
MAIN WORKFLOW
─────────────
/forge:issues  →  (code)  →  /forge:finish  →  (merge)  →  /forge:cleanup

That's it. 3 commands.


UTILITIES (not part of main workflow)
─────────────────────────────────────
/forge:new-issue <desc>   Create issue from description (skip browsing)
/forge:capture            Turn this chat into an issue
/forge:load <id>          Load issue into current session
/forge:worktree           Create worktree for existing branch
/forge:pr                 Open PR in browser
/forge:audit              Dry-run of /forge:finish
/forge:fix-pr             Re-run CodeRabbit fix loop

/forge:help               This message
```
