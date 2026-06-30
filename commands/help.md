---
description: List all available forge commands
---
# /help - Available Commands

## Default Output (no argument)

```
CORE WORKFLOW
─────────────
/forge:start [id | description]   Start an issue: branch + PR + worktree + background agent
                                  (no arg → shows your assigned issues)
    ↓  (background agent runs /forge:load)
/forge:finish                     Before pushing: cleanup → spec align → commit → push → PR ready

FIXING (after push)
───────────────────
/forge:fix-compliance   Fix SOC2 CI failures
/forge:fix-pr           Fix CodeRabbit / Qodo findings

UTILITIES
─────────
/forge:capture          Turn this conversation into a Linear issue
/forge:verify [id]      Prove the feature works in a real browser (Playwright)
/forge:hotfix           Document and backport an emergency push to main
/forge:release          Promote staging → production (with SOC2 audit trail)

/forge:help             This message
/forge:help <cmd>       Detailed help for a command
```

Background agents are managed natively:
- `claude agents` — dashboard of all running agents
- `claude attach <id>` — jump in (Ctrl+Z detaches; agent keeps running)
- `claude logs <id>` — peek at recent output
- `claude stop <id>` — pause

---

## Detailed Help

### /forge:help start
```
/forge:start [id | description]
  - Existing ID (e.g. BOL-420): fetches issue, skips to branch creation
  - Text description: creates a new Linear issue first
  - No arg: shows your assigned issues, ask which to start
Creates branch from staging, draft PR, worktree, then dispatches:
  claude --bg ... "/forge:load {ID} --unattended"
Monitor with `claude agents`.
```

### /forge:help load
```
/forge:load [id] [--unattended]
  Fetches Linear issue, researches codebase, drafts spec,
  posts spec as a Linear comment, then implements the change.
  --unattended: fully autonomous (no prompts) — used by background agents.
  Interactive mode keeps approval gates at spec draft and after implementation.
```

### /forge:help finish
```
/forge:finish
  Phase 1: git state snapshot + temp-file cleanup + linting (parallel)
  Phase 2: spec alignment — every changed file must trace to a Linear ticket
  Phase 3: commit + merge origin/staging
  Phase 4: push + PR ready + Linear → "In Review"
  Follow up with /forge:fix-compliance then /forge:fix-pr.
```

### /forge:help fix-compliance
```
/forge:fix-compliance [--tickets "BOL-1,BOL-2"]
  Reads the SOC2 compliance CI comment and run logs.
  Fixes: unspecced_changes, invalid_tickets, ghost_tickets, missing_documentation.
  Updates PR body so every changed file is covered by a ticket.
```

### /forge:help fix-pr
```
/forge:fix-pr
  Fetches CodeRabbit and Qodo review comments from the PR.
  Fixes Critical/Major findings via parallel subagents (grouped by file).
  Replies to each comment, resolves threads, waits for re-review.
  Loops until no Critical/Major remain.
```

### /forge:help capture
```
/forge:capture
  Reviews the current conversation, extracts feature description + spec,
  creates a Linear issue, posts the spec as a comment on it.
  No local files created.
```

### /forge:help verify
```
/forge:verify [id] [--unattended]
  Drives the running app in a real browser via Playwright against the
  acceptance criteria from the Linear issue. Auto-fixes breakage (max 3 cycles).
  On success: posts verified user story + screenshots to Linear.
  Requires: Playwright MCP + running dev server.
```

### /forge:help hotfix
```
/forge:hotfix [sha]
  For emergency direct pushes to main that bypass normal PR flow.
  Documents the incident, creates a Linear ticket, cherry-picks commits
  onto a new branch from staging, opens a backport PR.
```

### /forge:help release
```
/forge:release [--dry-run]
  Pre-flight: CI status, open PRs, staging vs main diff.
  Gathers PRs + Linear tickets in the release.
  Requires typed confirmation word (anti-accident).
  Fast-forwards main to staging, creates compliance archive,
  creates release ticket in Linear, notifies all resolved tickets.
```
