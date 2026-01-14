---
description: List all available commands
---

# /forge - Available Commands

Output the following command reference:

```
Available Commands:

-- Planning --------------------------------------------------------------

/issues           Browse your assigned Linear issues or create a new one.
                  Interactive workflow for issue management.

/new-issue <desc> Create a new Linear ticket from a description and
                  set up the full dev environment (branch, PR, worktree).

/ticketify        Turn your planning discussion into a Linear ticket.
                  Extracts requirements from chat and creates issue + spec files.

-- Development -----------------------------------------------------------

/ticket <id>      Start working on a Linear ticket. Fetches the issue,
                  saves requirements, and creates a technical plan.

/worktree         Create a git worktree for an existing branch.

/pr               Open the GitHub PR page for the current branch in browser.

-- Review ----------------------------------------------------------------

/audit            Check SOC2 compliance status (read-only). Shows what
                  /finish will find without making any changes.

/finish           Finalize your work before pushing. Runs cleanup, tests,
                  CodeRabbit review, and ensures everything is ready to merge.

/fix-pr           Auto-fix CodeRabbit review comments. Loops through
                  findings and fixes them one by one until the PR is clean.

-- Completion ------------------------------------------------------------

/cleanup          Clean up after a PR is merged. Removes worktree, deletes
                  branches, and kills the tmux session.

-- Help ------------------------------------------------------------------

/forge            Show this help message.
```
