---
description: List all available commands
---
# /help - Available Commands

## Handle Arguments

If user runs `/forge:help <command>`, show detailed help for that command:

### /forge:help start
```
/forge:start [issue-id] - Start Working on a Linear Issue
Shows assigned issues (or fetches by ID), creates branch from staging,
draft PR, worktree, opens tmux with Claude, runs /forge:load.
```

### /forge:help finish
```
/forge:finish - 12-Phase Compliance Workflow
1. Discovery  2. Cleanup  2.5 Simplify  3. Spec Alignment (CRITICAL)
4. Issue/Spec sync  5. Commit  5.5 Staging sync  6. Tests (/forge:add-tests)
7. Push + /code-review loop  8. PR Ready + Linear sync
8.5 PR Compliance Doc (/forge:verify-pr)  9. CodeRabbit loop
Builds PR with: TL;DR, Product Requirements, Technical Implementation,
Acceptance Criteria verification, Testing table, Audit Trail.
Requires plugins: code-simplifier, code-review (install via /forge:setup)
```

### /forge:help cleanup
```
/forge:cleanup - Clean Up After PR Merge
Verifies no uncommitted changes, confirms PR is MERGED, removes worktree,
deletes local+remote branch, kills tmux session.
```

### /forge:help add-tests
```
/forge:add-tests - Generate Test Coverage
Detects test patterns, identifies changes needing tests, generates unit +
integration tests (NO browser e2e), runs and commits. Called by /forge:finish.
```

### /forge:help fix-pr
```
/forge:fix-pr - Fix Code Review Findings
Part A: /code-review loop — run → fix → push → repeat until clean
Part B: CodeRabbit loop — poll → fix Major/Critical → push → repeat
```

### /forge:help verify-pr
```
/forge:verify-pr [--fix] - Build PR Compliance Document (SOC2)
Gathers tickets from commits, reads issues/ and specs/, runs MANDATORY ticket
traceability check, prompts for acceptance criteria verification, detects
unspecced changes, builds comprehensive PR body, cross-links to Linear.
Called by /forge:finish at Phase 8.5.
```

### /forge:help audit
```
/forge:audit - Read-Only Compliance Check
Checks: issue file, spec file, spec alignment, tests, Linear status,
PR status, PR body completeness (SOC2 sections), secrets. No changes made.
```

### /forge:help load
```
/forge:load <id> - Load Issue and Create Plan
Fetches Linear issue (recursive for parent/child), saves issues/{ID}.md,
researches codebase, creates specs/{id}.md. Asks approval at each step.
```

### /forge:help new-issue
```
/forge:new-issue <description> - Create Issue from Description
Creates Linear issue, optionally improves spec with AI, then sets up
branch, PR, worktree, tmux (full /forge:start workflow).
```

### /forge:help setup
```
/forge:setup - Install Development Tools & Plugins
Installs via Homebrew: iTerm2, tmux, Marta, Meld, Linear, Slack.
Configures ~/.tmux.conf for Claude/TUI. Installs code-simplifier and
code-review plugins.
```

### /forge:help suggest-cleanups
```
/forge:suggest-cleanups - Bulk Cleanup of Merged Worktrees/Branches
Discovers all worktrees+branches, classifies as cleanable (merged PR, your
authorship) or skipped (open PR, other user, dirty, etc.), presents plan,
executes after approval.
```

### /forge:help release
```
/forge:release [--dry-run] - Production Release
Pre-flight checks (CI, open PRs), gathers release contents (PRs, tickets),
builds summary, requires typed confirmation word, fast-forwards main to
staging, creates compliance archive, updates Linear.
```

### /forge:help tmux-list
`/forge:tmux-list` - Lists tmux sessions, lets you pick one, opens iTerm attached.

### /forge:help tile
`/forge:tile` - Tiles all tmux sessions into a single iTerm window with split panes (auto grid layout).

### /forge:help worktree
`/forge:worktree <id-or-branch>` - Creates worktree for existing branch, sets up env, opens tmux+Claude.

### /forge:help pr
`/forge:pr` - Opens PR in browser, or creates one if missing (draft/ready, auto-populates from Linear).

### /forge:help capture
`/forge:capture` - Extracts planning discussion into Linear issue + issues/{ID}.md + specs/{id}.md.

### /forge:help fix-compliance
`/forge:fix-compliance` - Fixes SOC2 CI failures: missing tickets, inherited merge tickets, invalid tickets.

### /forge:help release-media
`/forge:release-media` - Generates PDF/MP3/MP4 from markdown or ticket diffs (Mermaid, Google TTS, ffmpeg).

### /forge:help vscode
`/forge:vscode` - Opens current folder in VS Code.

### /forge:help gemini
`/forge:gemini` - Opens Gemini CLI in tmux/iTerm session.

### /forge:help codex
`/forge:codex` - Opens Codex CLI in tmux/iTerm session.

### /forge:help about
`/forge:about` - How Forge makes SOC2 compliance a competitive advantage.

## Default Output (no argument)

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
/forge:fix-compliance     Fix SOC2 compliance CI failures
/forge:add-tests          Generate unit/integration tests
/forge:release            Promote staging to production
/forge:tmux-list          List tmux sessions and attach in iTerm
/forge:tile               Tile tmux sessions into iTerm panes
/forge:suggest-cleanups   Bulk cleanup merged worktrees/branches
/forge:vscode             Open current folder in VS Code
/forge:gemini             Open Gemini CLI agent in tmux/iTerm
/forge:codex              Open Codex CLI agent in tmux/iTerm
/forge:setup              Install dev tools (iTerm, tmux, Marta, etc.)
/forge:release-media      Generate PDF/MP3/MP4 from markdown or tickets

/forge:about              Learn how Forge makes SOC2 a superpower
/forge:help               This message
/forge:help <cmd>         Detailed help for a command
```
