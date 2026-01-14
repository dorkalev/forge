---
description: List all available commands
---

# /forge - Available Commands

Output the following command reference:

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

/forge:forge            Show this help message.
```
