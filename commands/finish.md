---
description: Finalize work before pushing — cleanup, spec alignment, commit, sync, push, PR ready
---
# /finish - Finalize Work Before Pushing

**NEVER use:** `git stash`, `git checkout --`/`checkout .`, `git reset --hard`, `git clean -fd`, `git restore --staged --worktree`, `git revert` (without approval), `rm` on user files. **STOP and ask user instead.**

### Phase 1: Discover & Cleanup

Run in parallel:

```bash
# git state
git branch --show-current
git fetch origin staging
git log origin/staging..HEAD --first-parent --oneline
git diff origin/staging..HEAD --stat
git status --short
```

Also in parallel:
- Fetch Linear ticket via MCP (`linear_get_issue`) — read comments for spec posted by `/load`
- Remove temp files (*.pyc, __pycache__, .DS_Store, *.log) and run linting

After: you have the branch name, full diff, Linear ticket + spec comment, clean working tree.

### Phase 2: Spec Alignment (CRITICAL)

Compare **Linear ticket + spec comment** (authoritative) against the **actual diff**.

Classify misalignments:

| Type | Meaning | Resolution |
|------|---------|------------|
| UNSPECCED | Implemented but not in spec | Add to Linear ticket, create new issue, or remove code |
| INCOMPLETE | Spec'd but not implemented | Implement, descope with comment, or defer |
| SCOPE_CREEP | Beyond ticket scope | Expand scope in Linear, new issue, or remove code |

Present each to user, resolve via `linear_update_issue`, `linear_create_issue`, or `linear_save_comment`. **Do NOT proceed until aligned.**

### Phase 3: Commit & Sync

Sequential:

```bash
# Commit
git add -A
git commit -m "{feat|fix|chore}: {short description}"

# Sync with staging
git fetch origin staging
git merge origin/staging --no-edit
# Conflicts: prefer OURS unless THEIRS is a bug fix. Too complex → STOP and ask user.
```

### Phase 4: Push & Finalize

Push and immediately run these in parallel:

```bash
git push origin <branch-name>
```

After push:
- **PR Ready**: `gh pr ready <number>`, refine title if needed with `gh pr edit`
- **Update PR body**: Ensure it has Summary, Linear Tickets table, Changes (every changed file traced to a ticket), and Test Plan checklist
- **Linear Sync**: `linear_save_comment(issueId, body: "PR: <url>")` + `linear_update_issue(issueId, status: "In Review")`

**Tell the user:**
```
Done. Next steps:
  /forge:fix-compliance   fix SOC2 CI failures
  /forge:fix-pr           fix CodeRabbit / Qodo findings
```

## Quality Gates
Do NOT push if: unspecced features, spec misalignment, merge conflicts unresolved.

## Error Handling
- **Linear MCP fails**: ask user to check `.mcp.json`
- **Git conflicts**: STOP, ask user
