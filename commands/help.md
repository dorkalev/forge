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
LOCAL_VERSION="1.12.0"

if [ "$REMOTE_VERSION" != "$LOCAL_VERSION" ]; then
  echo "⚠️  UPDATE AVAILABLE: forge $REMOTE_VERSION (you have $LOCAL_VERSION)"
  echo "   Run: /plugin update"
  echo ""
fi
```

If an update is available, show the notice BEFORE the command list.

## Handle Arguments

If user runs `/forge:help <command>`, show detailed help for that command.

### /forge:help start

```
/forge:start - Start Working on a Linear Issue

Shows your assigned Linear issues, lets you pick one (or create new),
then automatically:
  1. Creates branch from staging
  2. Creates draft PR
  3. Creates worktree
  4. Opens tmux session with Claude
  5. Runs /forge:load to create technical plan
```

### /forge:help finish

```
/forge:finish - Finalize Work Before Pushing

Runs a 9-phase compliance workflow:
  1. Discovery        - Analyze branch, diff changes since staging
  2. Cleanup          - Remove temp files, run formatters
  3. Spec Alignment   - Verify all changes covered in specs
  4. Issue & Spec     - Update files, sync to Linear
  5. Commit           - Stage and commit changes
  6. Tests            - Generate tests (/forge:add-tests)
  7. Code Review      - Push → /code-review → fix → repeat until clean
  8. PR Ready         - Convert draft to ready, update Linear
  9. CodeRabbit       - Wait → check → fix → repeat until clean
```

### /forge:help cleanup

```
/forge:cleanup - Clean Up After PR Merge

Safely removes a worktree after its PR is merged:
  1. Verifies no uncommitted changes
  2. Confirms PR is MERGED (not just closed)
  3. Removes worktree directory
  4. Deletes local and remote branch
  5. Kills associated tmux session
```

### /forge:help add-tests

```
/forge:add-tests - Generate Test Coverage

Generates unit and integration tests for your changes:
  1. Detects project test patterns
  2. Identifies what needs tests
  3. Generates unit tests (functions) + integration tests (pipelines)
  4. NO browser-based e2e tests
  5. Runs tests to verify
  6. Commits the tests
```

### /forge:help fix-pr

```
/forge:fix-pr - Fix Code Review Findings

Runs two sequential fix loops:

Part A: /code-review loop (Anthropic plugin)
  - Run /code-review → fix issues → push → repeat until clean

Part B: CodeRabbit loop (GitHub bot)
  - Wait 3 min → check comments → fix Major/Critical → push → repeat
```

### /forge:help audit

```
/forge:audit - Dry-Run Compliance Check

Read-only check of SOC2 compliance status:
  - Issue file exists
  - Spec file exists and aligned
  - Tests exist
  - Linear issue linked
  - PR has issue table
  - No secrets in diff

Does NOT make changes - just reports status.
```

### /forge:help load

```
/forge:load <id> - Load Issue and Create Plan

Fetches a Linear issue and creates technical implementation plan:
  1. Fetches issue from Linear
  2. Saves to issues/{ID}.md
  3. Analyzes codebase for implementation
  4. Creates technical spec in specs/
```

### /forge:help new-issue

```
/forge:new-issue <description> - Create Issue from Description

Quickly creates a new Linear issue from a description:
  1. Creates issue in Linear
  2. Optionally improves spec with AI
  3. Continues to /forge:start workflow
```

### /forge:help setup

```
/forge:setup - Install Development Tools

Installs recommended tools via Homebrew:
  - iTerm2 (terminal)
  - tmux (session management)
  - Marta (file manager)
  - Meld (diff tool)
  - Linear (issue tracking)
  - Slack (communication)
  - ~/.tmux.conf optimized for Claude

Also recommends: Warp, /code-review plugin
```

### /forge:help tmux-list

```
/forge:tmux-list - List and Attach to Tmux Sessions

Shows all active tmux sessions and lets you pick one:
  1. Lists sessions with windows count, attached status
  2. Select from menu
  3. Opens iTerm and attaches to selected session
```

### /forge:help about

```
/forge:about - About Forge

Explains how Forge turns SOC2 compliance into a competitive advantage
by baking compliance into the natural development workflow.
```

## Default Output (no argument)

If no command specified, output the following:

```
MAIN WORKFLOW
─────────────
/forge:start  →  (code)  →  /forge:finish  →  (merge)  →  /forge:cleanup

That's it. 3 commands.


UTILITIES (not part of main workflow)
─────────────────────────────────────
/forge:new-issue <desc>   Create issue from description (skip browsing)
/forge:capture            Turn this chat into an issue
/forge:load <id>          Fetch issue and create technical plan
/forge:worktree           Create worktree for existing branch
/forge:pr                 Open PR in browser
/forge:audit              Dry-run of /forge:finish
/forge:fix-pr             Fix code review + CodeRabbit findings
/forge:add-tests          Generate unit/integration tests
/forge:tmux-list          List tmux sessions and attach in iTerm
/forge:setup              Install dev tools (iTerm, tmux, Marta, etc.)

/forge:about              Learn how Forge makes SOC2 a superpower
/forge:help               This message
/forge:help <cmd>         Detailed help for a command
```
