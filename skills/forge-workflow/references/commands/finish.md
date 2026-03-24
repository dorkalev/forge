---
description: Run pre-push compliance workflow (cleanup, tests, sync)
---
# /finish - Finalize Work Before Pushing

**NEVER use:** `git stash`/`stash drop`/`stash pop`, `git checkout --`/`checkout .`, `git reset --hard`/`HEAD~`, `git clean -fd`/`-f`, `git restore --staged --worktree`, `git revert` (without approval), `rm` on user files. **STOP and ask user instead.**

Use TaskCreate at START for each phase, update to `in_progress` then `completed`.

Documentation: `issues/` = Product (WHAT & WHY, no code), `specs/` = Technical (HOW).

### Phase 1: Discover & Cleanup

Run ALL of these in parallel (single message, multiple tool calls):

**Parallel group A — git state:**
```bash
git branch --show-current
git fetch origin staging
git log origin/staging..HEAD --first-parent --oneline
git diff origin/staging..HEAD --stat
git status --short
```

**Parallel group B — context (run as parallel Task agents or tool calls):**
- Read `issues/BOL-*.md` and `specs/*.md` files (Glob + Read)
- Fetch Linear ticket via MCP (`linear_get_issue`)
- Cleanup: remove temp files (*.pyc, __pycache__, .DS_Store, *.log), run linting

After all complete, you have: branch name, full diff, issues/specs content, Linear ticket, clean working tree.

### Phase 2: Spec Alignment (CRITICAL)

Ensure alignment between **Linear ticket** (authoritative), **`issues/`**, **`specs/`**, and **actual diff**.

Compare all 4 sources, classify misalignments:

| Type | Meaning | Resolution |
|------|---------|------------|
| UNSPECCED | Implemented but not in any spec | Add to Linear, create new issue, or remove code |
| DRIFT | Linear ≠ issues/ file | Sync from Linear, or update Linear |
| INCOMPLETE | Spec'd but not implemented | Implement, descope with comment, or defer |
| SCOPE_CREEP | Beyond all specs | Expand scope in Linear, new issue, or remove |

Present each to user, resolve via `linear_update_issue`, `linear_create_issue`, or `linear_create_comment`.
**Do NOT proceed until aligned.**

### Phase 3: Update Docs (parallel)

Launch ALL of these in parallel (single message, multiple tool calls):

1. **Update issues/ file** — `- [ ]` → `- [x]`, sync to Linear via `linear_update_issue`
2. **Update specs/ file** — reflect current implementation
3. **`/forge:update-domain-docs`** — refresh domain docs affected by code changes (Task subagent)
4. **`/forge:update-docs-toc`** — update CLAUDE.md documentation section (Task subagent)
5. **`/forge:inspect-architecture`** — check architecture docs vs code, report-only mode (no interactive prompts). Checks system shape only: services, communication patterns, structural rules (not product, not implementation details). If FAIL findings exist, flag for user attention before proceeding.

Wait for all to complete before proceeding.

### Phase 4: Commit, Sync & Test

Sequential — each step depends on the previous:
```bash
# Commit
git add -A
git commit -m "chore: cleanup and consolidation for [feature-name]"

# Sync with staging
git fetch origin staging
git merge origin/staging --no-edit
# If conflicts: prefer OURS unless THEIRS is bug fix. Too complex → STOP and ask user.

# Test
```
Invoke `/forge:add-tests` — generates tests, runs them, commits.

### Phase 5: Push & Finalize

**Step 1 — Push:**
```bash
git push origin <branch-name>
```

**Step 2 — Run these in parallel (single message, multiple tool calls):**

1. **PR Ready** — `gh pr ready <number>`, refine title, `gh pr edit`
2. **Linear Sync** — `linear_create_comment(issueId, body: "PR: <url>")` + `linear_update_issue(issueId, status: "In Review")`
3. **Compliance Doc** — invoke `/forge:verify-pr --fix` (builds PR into SOC2 audit record)

**Step 3 — Ask user:**

After compliance doc is built, AskUserQuestion — Header: "Post-push", Question: "Run post-push review fixers?", Options:
- "Run /fix-compliance then /fix-pr" (recommended) — waits for CI, fixes SOC2 compliance failures, then fixes CodeRabbit/Greptile/Aikido findings
- "Run /fix-compliance only" — just SOC2 compliance
- "Run /fix-pr only" — just review bot findings
- "Skip" — done for now

If user selects any fixer: invoke the selected skill(s) sequentially. `/fix-compliance` first (it often requires a re-push which triggers new reviews), then `/fix-pr`.

## Quality Gates
Do NOT push if: tests fail, unspecced features, spec misalignment, acceptance criteria unverified.

## Output
Report: files changed, specs verified, tests added, PR ready (not draft), Linear → "In Review", compliance doc built.

## Error Handling
- **Linear MCP fails**: ask user to check `.mcp.json`  |  **Tests fail**: stop, report, await
- **Git conflicts**: STOP, ask user
