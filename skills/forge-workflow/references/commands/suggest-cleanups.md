---
description: Discover cleanable worktrees and branches, build a safe cleanup plan, and execute after user approval.
---
# /suggest-cleanups - Safe Bulk Cleanup of Worktrees and Branches

NEVER delete anything without explicit user approval. NEVER touch branches with open PRs or owned by other users.

## Phase 1: Discovery

**1.1** Load `.forge` for `WORKTREE_REPO_PATH` and `WORKTREE_BASE_PATH`.

**1.2** Get current user: `CURRENT_USER=$(gh api user --jq .login)`

**1.3** List worktrees: `git -C "${WORKTREE_REPO_PATH}" worktree list --porcelain`. Parse path, branch, flags. Exclude main worktree.

**1.4** List local branches: `git -C "${WORKTREE_REPO_PATH}" branch --format='%(refname:short)'`. Exclude `main`, `master`, `staging`, `develop`.

**1.5** List remote branches:
```bash
git -C "${WORKTREE_REPO_PATH}" fetch --prune
git -C "${WORKTREE_REPO_PATH}" branch -r --format='%(refname:short)' | grep '^origin/' | sed 's|^origin/||'
```
Exclude `main`, `master`, `staging`, `develop`, `HEAD`.

**1.6** Get open PRs (CRITICAL exclusion set — prevents auto-closing PRs):
```bash
gh pr list --repo "${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}" --state open --json headRefName,number,title,author --limit 200
```
Derive repo from `git remote get-url origin` if not in `.forge`.

**1.7** For each non-protected, non-open-PR branch, check PR status:
```bash
gh pr list --repo "${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}" --state all --head "${BRANCH}" --json number,state,author,title,url --limit 1
```

## Phase 2: Classification

**Cleanable** (ALL must be true): PR MERGED, author matches CURRENT_USER, not protected, not open PR, worktree clean (no uncommitted changes, no unpushed commits).

**Skipped** with reason: "Open PR", "Not your PR", "PR closed (not merged)", "No PR found", "Dirty worktree", "Protected branch".

Worktree cleanliness check:
```bash
git -C "${WORKTREE_PATH}" status --porcelain
git -C "${WORKTREE_PATH}" log origin/${BRANCH}..HEAD --oneline 2>/dev/null
```

## Phase 3: Present Cleanup Plan

Display: GitHub user, repo, "Will Clean Up" table (`| Branch | PR | Action |`), "Skipped" table (`| Branch | Reason | Details |`). If nothing cleanable, report that and exit.

## Phase 4: User Approval

AskUserQuestion — Header: "Cleanup", Question: "Review the cleanup plan above. How to proceed?", Options: "Execute cleanup", "Cancel". Custom input → adjust plan and re-ask.

## Phase 5: Execute Cleanup

For each cleanable branch:
```bash
# 1. Remove worktree (if exists)
git -C "${WORKTREE_REPO_PATH}" worktree remove "${WORKTREE_PATH}" --force
rm -rf "${WORKTREE_PATH}" 2>/dev/null
# 2. Delete local branch
git -C "${WORKTREE_REPO_PATH}" branch -D "${BRANCH}" 2>/dev/null
# 3. Delete remote branch
git -C "${WORKTREE_REPO_PATH}" push origin --delete "${BRANCH}" 2>/dev/null
# 4. Kill tmux session (try both branch name and issue ID)
tmux kill-session -t "${BRANCH}" 2>/dev/null || true
ISSUE_ID=$(echo "${BRANCH}" | grep -oE '^[A-Za-z]+-[0-9]+' | tr '[:lower:]' '[:upper:]')
[ -n "${ISSUE_ID}" ] && tmux kill-session -t "${ISSUE_ID}" 2>/dev/null || true
```
Report progress per branch. Continue on errors.

## Phase 6: Prune and Verify
```bash
git -C "${WORKTREE_REPO_PATH}" fetch --prune
git -C "${WORKTREE_REPO_PATH}" worktree prune
```
Show remaining worktrees, local branches, remote branches. Report summary: cleaned count, skipped count, errors.

## Important Rules
- **NEVER** delete a branch with an open PR (auto-closes it)
- **NEVER** delete branches owned by other users
- **Protected branches** (`main`, `master`, `staging`, `develop`) are NEVER touched
- **No-PR branches** are "manual review needed", NEVER auto-deleted
- All `git` commands use `git -C` to avoid cwd issues
