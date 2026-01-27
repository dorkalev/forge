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
LOCAL_VERSION="1.20.0"

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

Runs an 11-phase compliance workflow:
  1. Discovery        - Analyze branch, diff changes since staging
  2. Cleanup          - Remove temp files, run formatters
  2.5 Simplify        - Code simplification (requires code-simplifier plugin)
  3. Spec Alignment   - Verify all changes covered in specs
  4. Issue & Spec     - Update files, sync to Linear
  5. Commit           - Stage and commit changes
  5.5 Sync            - Merge latest staging into branch
  6. Tests            - Generate tests (/forge:add-tests)
  7. Code Review      - Push → /code-review → fix → repeat until clean
  8. PR Ready         - Convert draft to ready, update Linear
  8.5 PR Document     - Build comprehensive PR audit record (/forge:verify-pr)
  9. CodeRabbit       - Wait → check → fix → repeat until clean

Phase 8.5 builds PR with: TL;DR, Product Requirements (from issues/),
Technical Implementation (from specs/), Acceptance Criteria verification,
Testing table, and Audit Trail. Auditors can understand the change from PR alone.

Requires plugins: code-simplifier, code-review (install via /forge:setup)
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

### /forge:help verify-pr

```
/forge:verify-pr - Build Comprehensive PR Compliance Document (SOC2)

Transforms the PR into a self-contained SOC2 audit record:

  Phase 1: Gather Sources
    - Extract tickets from commits
    - Read issues/{TICKET}.md for product requirements
    - Read specs/{feature}.md for technical details
    - Fetch Linear issue status

  Phase 2: Verification
    - Prompt for verification of each acceptance criterion
    - Detect unspecced changes in diff

  Phase 3: Build PR Body
    - TL;DR (one-sentence summary)
    - Linear Tickets table (with status)
    - Product Requirements (full issues/ content)
    - Technical Implementation (condensed specs/)
    - Acceptance Criteria (with verification evidence)
    - Testing & Verification table
    - Audit Trail

  Phase 4: Update PR
    - Update PR title and body
    - Validate ticket links (404 check)
    - Add cross-links to Linear issues

Usage:
  /forge:verify-pr          Check compliance (report only)
  /forge:verify-pr --fix    Build comprehensive PR body

An auditor can understand the entire change from the PR alone.
Called automatically by /forge:finish at Phase 8.5.
```

### /forge:help audit

```
/forge:audit - Dry-Run Compliance Check

Read-only check of SOC2 compliance status:
  - Issue file exists with Summary and Acceptance Criteria
  - Spec file exists and aligned with implementation
  - Tests exist and pass
  - Linear issue linked
  - PR has issue table
  - PR body completeness:
    - Has TL;DR, Product Requirements, Technical Implementation sections
    - All acceptance criteria have verification status
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
/forge:setup - Install Development Tools & Plugins

Installs recommended tools via Homebrew:
  - iTerm2 (terminal)
  - tmux (session management)
  - Marta (file manager)
  - Meld (diff tool)
  - Linear (issue tracking)
  - Slack (communication)
  - ~/.tmux.conf optimized for Claude

Installs Claude Code plugins:
  - code-simplifier (code clarity for /finish)
  - code-review (multi-agent review for /finish)
```

### /forge:help tmux-list

```
/forge:tmux-list - List and Attach to Tmux Sessions

Shows all active tmux sessions and lets you pick one:
  1. Lists sessions with windows count, attached status
  2. Select from menu
  3. Opens iTerm and attaches to selected session
```

### /forge:help tile

```
/forge:tile - Tile Tmux Sessions in iTerm Panes

Creates a single iTerm window with split panes for all tmux sessions:
  1. Finds all tmux sessions
  2. Creates one iTerm window
  3. Splits into grid (2x1, 2x2, 3x2, etc.)
  4. Attaches each pane to a tmux session

Navigate: Cmd+[ / Cmd+]  |  Maximize: Cmd+Shift+Enter
```

### /forge:help worktree

```
/forge:worktree <issue-id-or-branch> - Create Worktree for Existing Branch

Creates a git worktree for an existing remote branch:
  1. Finds branch by issue ID (e.g., PROJ-248) or exact name
  2. Creates worktree in configured WORKTREE_BASE_PATH
  3. Copies .env and .claude, symlinks .forge
  4. Opens tmux session with Claude
  5. Auto-runs /load if issue ID detected in branch name
```

### /forge:help pr

```
/forge:pr - Open Pull Request in Browser

Opens or creates the PR for the current branch:
  1. Gets current feature branch name
  2. Checks if PR exists for this branch
  3. If exists: opens in browser
  4. If not: offers to create draft or ready PR
  5. Auto-populates PR with Linear issue info if found
```

### /forge:help capture

```
/forge:capture - Turn Planning Discussion into Linear Issue

Formalizes the current conversation into structured requirements:
  1. Extracts feature name, requirements, and technical details
  2. Prompts for priority and labels
  3. Creates Linear issue
  4. Saves issues/{ID}.md (product requirements)
  5. Saves specs/{ID}-{name}.md (technical spec)
```

### /forge:help vscode

```
/forge:vscode - Open in VS Code

Opens the current working directory in Visual Studio Code.
```

### /forge:help gemini

```
/forge:gemini - Open Gemini CLI Agent

Opens Gemini CLI in a new iTerm2/tmux session:
  1. Creates tmux session named gemini-{folder}
  2. Launches gemini CLI in the session
  3. Opens new iTerm window attached to the session
```

### /forge:help codex

```
/forge:codex - Open Codex CLI Agent

Opens Codex CLI in a new iTerm2/tmux session:
  1. Creates tmux session named codex-{folder}
  2. Launches codex CLI in the session
  3. Opens new iTerm window attached to the session
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
/forge:pr                 Open PR in browser (or create if missing)
/forge:audit              Dry-run of /forge:finish
/forge:verify-pr          Build comprehensive PR audit document (SOC2)
/forge:fix-pr             Fix code review + CodeRabbit findings
/forge:add-tests          Generate unit/integration tests
/forge:tmux-list          List tmux sessions and attach in iTerm
/forge:tile               Tile tmux sessions into iTerm panes
/forge:vscode             Open current folder in VS Code
/forge:gemini             Open Gemini CLI agent in tmux/iTerm
/forge:codex              Open Codex CLI agent in tmux/iTerm
/forge:setup              Install dev tools (iTerm, tmux, Marta, etc.)

/forge:about              Learn how Forge makes SOC2 a superpower
/forge:help               This message
/forge:help <cmd>         Detailed help for a command
```
