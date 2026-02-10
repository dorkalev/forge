---
description: Run pre-push compliance workflow (cleanup, tests, CodeRabbit review, sync)
---
# /finish - Finalize Work Before Pushing

**NEVER use:** `git stash`/`stash drop`/`stash pop`, `git checkout --`/`checkout .`, `git reset --hard`/`HEAD~`, `git clean -fd`/`-f`, `git restore --staged --worktree`, `git revert` (without approval), `rm` on user files. **STOP and ask user instead.**

Use TodoWrite at START, update each to `in_progress` then `completed`:
```
TodoWrite([
  { content: "Phase 1: Discovery & Analysis", status: "pending" },
  { content: "Phase 2: Cleanup & Consolidation", status: "pending" },
  { content: "Phase 2.5: Code Simplification", status: "pending" },
  { content: "Phase 3: Spec Alignment Verification", status: "pending" },
  { content: "Phase 4: Issue & Spec File Management", status: "pending" },
  { content: "Phase 5: Commit Changes", status: "pending" },
  { content: "Phase 5.5: Sync with Staging", status: "pending" },
  { content: "Phase 6: Test Generation", status: "pending" },
  { content: "Phase 7: Push & Code Review Loop", status: "pending" },
  { content: "Phase 8: PR Ready & Linear Sync", status: "pending" },
  { content: "Phase 8.5: Build PR Compliance Document", status: "pending" },
  { content: "Phase 9: CodeRabbit Loop", status: "pending" }
])
```
Documentation: `issues/` = Product (WHAT & WHY, no code), `specs/` = Technical (HOW).

### Phase 1: Discovery & Analysis
Get branch name, locate `issues/` file, parse requirements, analyze all changes:
```bash
git log staging..HEAD --first-parent --oneline
git diff staging...HEAD --stat
git status --short
git diff --stat          # unstaged
git diff --cached --stat # staged
```
Phase 3 must verify BOTH committed and uncommitted changes.

### Phase 2: Cleanup & Consolidation
Remove temp files only (*.pyc, __pycache__, .DS_Store, *.log), remove accidentally-tracked gitignored files, run linting/formatting. **Never delete source code, tests, or config files.**

### Phase 2.5: Code Simplification
If source files (*.py, *.ts, *.tsx, *.js, *.jsx) changed since staging, invoke `code-simplifier` (Task tool, subagent_type="code-simplifier:code-simplifier"). If not installed, offer to install or skip.

### Phase 3: Spec Alignment Verification (CRITICAL)
Ensure alignment between **Linear ticket** (authoritative), **`issues/`**, **`specs/`**, and **actual diff**.

**3.1** Gather: `git diff staging...HEAD`, `git diff`, `git diff --cached`, read issues/ and specs/ files, fetch Linear ticket via MCP.
**3.2** Compare all 4 sources in structured analysis, then classify misalignments:

| Type | Meaning | Resolution Options |
|------|---------|-------------------|
| UNSPECCED | Implemented but not in any spec | Add to Linear, create new issue, or remove code |
| DRIFT | Linear ≠ issues/ file | Sync from Linear, or update Linear |
| INCOMPLETE | Spec'd but not implemented | Implement, descope with comment, or defer |
| SCOPE_CREEP | Beyond all specs | Expand scope in Linear, new issue, or remove |

**3.3** Present each to user, resolve via `linear_update_issue`, `linear_create_issue`, or `linear_create_comment`.
**3.4** Verify: all diffs map to Linear, issues/ matches Linear, specs/ covers all, no undocumented code remains. **Do NOT proceed until aligned.**

### Phase 4: Issue & Spec File Management
Update `issues/{ISSUE_ID}.md` (`- [ ]` → `- [x]`, product-focused), sync to Linear via `linear_update_issue` (Summary, Acceptance Criteria, Out of Scope), update `specs/{feature-name}.md`.

### Phase 5: Commit Changes
```bash
git status --short
# If uncommitted:
git add -A
git commit -m "chore: cleanup and consolidation for [feature-name]"
```
Do NOT push yet.

### Phase 5.5: Sync with Staging
```bash
git fetch origin staging
git merge origin/staging --no-edit
```
**If conflicts**: both add different → keep both; same line → prefer OURS unless THEIRS is bug fix; THEIRS deletes what OURS modified → keep OURS; too complex → **STOP and ask user**. After: `git add -A && git commit -m "merge: sync with staging"`

### Phase 6: Test Generation
Invoke `/forge:add-tests` — generates tests, runs them, commits.

### Phase 7: Push & Code Review Loop
1. `git push origin <branch-name>`
2. Run `/code-review` (Anthropic plugin — install: `/plugin add anthropics/claude-plugins-official/plugins/code-review`; 5 agents, 80+ confidence)
3. If issues: fix, re-test, commit (`fix: address code review findings`), push, re-run. **Repeat until clean**

### Phase 8: PR Ready & Linear Sync
1. Find PR: `gh pr list --head <branch-name> --base staging --json number,url,isDraft`
2. `gh pr ready <pr-number>`
3. **Refine title to express essence** — Bad: "Delete tfvars files, use GitHub Environment variables" → Good: "Make GitHub Environments the single source of truth for Terraform". Present suggested vs current, let user accept/keep/edit via `gh pr edit`.
4. `linear_create_comment(issueId, body: "PR: <url>")` + `linear_update_issue(issueId, status: "In Review")`

### Phase 8.5: Build PR Compliance Document (SOC2)
Invoke `/forge:verify-pr --fix` — builds PR into self-contained audit record. **Do NOT proceed until it passes.**

### Phase 9: CodeRabbit Loop
1. `sleep 180`, fetch `gh api repos/{owner}/{repo}/pulls/{pr-number}/comments`
2. Filter `coderabbitai[bot]` — fix `_Critical_` and `_Major_` only
3. Fix, commit (`fix: address CodeRabbit findings`), push, reply (`Fixed in commit {hash}`). **Repeat until clean**

## Quality Gates
Do NOT push if: tests fail, unresolved review issues, unspecced features, spec misalignment, PR missing sections (TL;DR, Product Requirements, Technical Implementation), acceptance criteria unverified.

## Output
Report: files changed, specs verified, tests added, code-review passed, PR ready (not draft), Linear → "In Review", compliance doc built, CodeRabbit clean.

## Error Handling
- **Linear MCP fails**: ask user to check `.mcp.json`  |  **Tests fail**: stop, report, await
- **Git conflicts**: STOP, ask user  |  **CodeRabbit fails**: retry, if persistent report
