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
LOCAL_VERSION="1.0.0"  # Will be replaced by actual check when Claude Code provides this

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
Available Commands:

-- Planning --------------------------------------------------------------

/forge:issues           Browse your assigned Linear issues or create a new one.
                        Interactive workflow for issue management.

/forge:new-issue <desc> Create a new Linear ticket from a description and
                        set up the full dev environment (branch, PR, worktree).

/forge:ticketify        Turn your planning discussion into a Linear ticket.
                        Extracts requirements from chat and creates issue + spec files.

-- Development -----------------------------------------------------------

/forge:ticket <id>      Start working on a Linear ticket. Fetches the issue,
                        saves requirements, and creates a technical plan.

/forge:worktree         Create a git worktree for an existing branch.

/forge:pr               Open the GitHub PR page for the current branch in browser.

-- Review ----------------------------------------------------------------

/forge:audit            Check SOC2 compliance status (read-only). Shows what
                        /forge:finish will find without making any changes.

/forge:finish           Finalize your work before pushing. Runs cleanup, tests,
                        CodeRabbit review, and ensures everything is ready to merge.

/forge:fix-pr           Auto-fix CodeRabbit review comments. Loops through
                        findings and fixes them one by one until the PR is clean.

-- Completion ------------------------------------------------------------

/forge:cleanup          Clean up after a PR is merged. Removes worktree, deletes
                        branches, and kills the tmux session.

-- Help ------------------------------------------------------------------

/forge:help             Show this help message.
```
