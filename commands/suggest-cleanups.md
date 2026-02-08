---
description: Discover cleanable worktrees and branches, build a safe cleanup plan, and execute after user approval.
---

# /suggest-cleanups - Safe Bulk Cleanup of Worktrees and Branches

You are an automation assistant that safely identifies and cleans up stale worktrees and branches. You NEVER delete anything without explicit user approval, and you NEVER touch branches with open PRs or branches owned by other users.

## Your Mission

When the user runs `/suggest-cleanups`, execute this workflow:

---

## Phase 1: Discovery

### Step 1: Load Configuration

Read the `.forge` file for worktree paths:

```bash
WORKTREE_REPO_PATH=$(grep '^WORKTREE_REPO_PATH=' .forge | cut -d= -f2)
WORKTREE_BASE_PATH=$(grep '^WORKTREE_BASE_PATH=' .forge | cut -d= -f2)
```

If `.forge` is not found, try the parent directory or ask the user.

### Step 2: Identify Current GitHub User

```bash
CURRENT_USER=$(gh api user --jq .login)
```

If `gh` CLI fails, report error and suggest `gh auth login`.

### Step 3: Gather All Worktrees

```bash
git -C "${WORKTREE_REPO_PATH}" worktree list --porcelain
```

Parse each worktree entry to extract:
- `worktree_path`: the filesystem path
- `branch`: the branch checked out (from the `branch refs/heads/...` line)
- `bare` or `detached` flags

Exclude the main worktree (the one at `WORKTREE_REPO_PATH` itself).

### Step 4: Gather All Local Branches

```bash
git -C "${WORKTREE_REPO_PATH}" branch --format='%(refname:short)'
```

Exclude protected branches: `main`, `master`, `staging`, `develop`.

### Step 5: Gather All Remote Branches

```bash
git -C "${WORKTREE_REPO_PATH}" fetch --prune
git -C "${WORKTREE_REPO_PATH}" branch -r --format='%(refname:short)' | grep '^origin/' | sed 's|^origin/||'
```

Exclude protected branches: `main`, `master`, `staging`, `develop`, `HEAD`.

### Step 6: Get Open PRs (Exclusion Set)

**CRITICAL SAFETY STEP** — This prevents auto-closing open PRs when deleting remote branches.

```bash
gh pr list --repo "${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}" --state open --json headRefName,number,title,author --limit 200
```

If the repo owner/name aren't in `.forge`, derive from `git remote get-url origin`.

Build an exclusion set: any branch that appears in `headRefName` of an open PR is **never** deleted.

### Step 7: Get All Closed/Merged PRs for Non-Protected Branches

For each branch that is NOT in the open-PR exclusion set and NOT a protected branch, check its PR status:

```bash
gh pr list --repo "${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}" --state all --head "${BRANCH}" --json number,state,author,title,url --limit 1
```

Batch this efficiently — you can query multiple branches. For each branch, record:
- `pr_number`, `pr_state` (MERGED / CLOSED / null if no PR)
- `pr_author` (the `login` field)
- `pr_url`

---

## Phase 2: Classification

For each branch, determine its cleanup classification:

### Cleanable (will be included in the plan)

A branch is cleanable if ALL of these are true:
1. PR state is `MERGED`
2. PR author matches `CURRENT_USER`
3. Branch is NOT protected (`main`, `master`, `staging`, `develop`)
4. Branch is NOT in the open-PR exclusion set
5. If a worktree exists for the branch: no uncommitted changes and no unpushed commits

### Skipped (shown but not acted on)

A branch is skipped with a reason:
- **"Open PR"** — branch has an open PR (from Step 6 exclusion set)
- **"Not your PR"** — PR exists but `author.login` != `CURRENT_USER`
- **"PR closed (not merged)"** — PR was closed without merging; may need manual review
- **"No PR found"** — no PR exists for this branch; needs manual review
- **"Dirty worktree"** — worktree has uncommitted changes or unpushed commits
- **"Protected branch"** — branch is in the protected set

### Worktree Status Check

For each worktree that maps to a cleanable branch, verify it's clean:

```bash
# Uncommitted changes
git -C "${WORKTREE_PATH}" status --porcelain

# Unpushed commits
git -C "${WORKTREE_PATH}" log origin/${BRANCH}..HEAD --oneline 2>/dev/null
```

If either is non-empty, move the branch from "Cleanable" to "Skipped" with reason "Dirty worktree".

---

## Phase 3: Present Cleanup Plan

Display the full plan to the user:

```
## Cleanup Plan

**GitHub user:** {CURRENT_USER}
**Repository:** {GITHUB_REPO_OWNER}/{GITHUB_REPO_NAME}

### Will Clean Up ({N} branches)

| Branch | PR | Action |
|--------|----|--------|
| eng-100-fix-bug | #42 (MERGED) | Remove worktree, delete local + remote branch, kill tmux |
| eng-101-add-feature | #43 (MERGED) | Delete local + remote branch |
| eng-102-refactor | #44 (MERGED) | Delete remote branch (no local) |

### Skipped ({M} branches)

| Branch | Reason | Details |
|--------|--------|---------|
| eng-200-wip | Open PR | PR #50 is still open |
| eng-201-other | Not your PR | PR #51 by @teammate |
| eng-202-closed | PR closed (not merged) | PR #52 closed without merge |
| eng-203-orphan | No PR found | Manual review needed |
| eng-204-dirty | Dirty worktree | Has uncommitted changes |
| main | Protected branch | — |
```

If there are no cleanable branches, report that and exit:

```
## No Cleanup Needed

All branches are either protected, have open PRs, belong to other users, or need manual review.

### Current Branch Status ({N} branches)

{Show the skipped table}
```

---

## Phase 4: User Approval

Use `AskUserQuestion` to get the user's decision:

- Header: "Cleanup"
- Question: "Review the cleanup plan above. How would you like to proceed?"
- Options:
  1. **"Execute cleanup"** — "Delete all listed worktrees, branches, and tmux sessions"
  2. **"Cancel"** — "Don't delete anything"

If the user selects **"Cancel"**: Stop immediately with no changes.

If the user selects **"Execute cleanup"**: Proceed to Phase 5.

If the user provides custom input (via "Other"): Treat as instructions to modify the plan. Adjust the plan, re-display it, and ask again.

---

## Phase 5: Execute Cleanup

Process each cleanable branch in order. For each branch:

### Step 1: Remove Worktree (if exists)

```bash
WORKTREE_PATH="${WORKTREE_BASE_PATH}/${BRANCH}"
if git -C "${WORKTREE_REPO_PATH}" worktree list | grep -q "${BRANCH}"; then
  git -C "${WORKTREE_REPO_PATH}" worktree remove "${WORKTREE_PATH}" --force
  rm -rf "${WORKTREE_PATH}" 2>/dev/null
fi
```

### Step 2: Delete Local Branch (if exists)

```bash
git -C "${WORKTREE_REPO_PATH}" branch -D "${BRANCH}" 2>/dev/null
```

### Step 3: Delete Remote Branch (if exists)

```bash
git -C "${WORKTREE_REPO_PATH}" push origin --delete "${BRANCH}" 2>/dev/null
```

### Step 4: Kill Tmux Session (if exists)

```bash
tmux kill-session -t "${BRANCH}" 2>/dev/null || true
```

Also try the issue identifier as session name (e.g., `ENG-100`):

```bash
# Extract issue identifier pattern from branch name
ISSUE_ID=$(echo "${BRANCH}" | grep -oE '^[A-Za-z]+-[0-9]+' | tr '[:lower:]' '[:upper:]')
if [ -n "${ISSUE_ID}" ]; then
  tmux kill-session -t "${ISSUE_ID}" 2>/dev/null || true
fi
```

### Step 5: Report Progress

After each branch, output:

```
- {BRANCH}: Cleaned (worktree: {yes/no}, local: {yes/no}, remote: {yes/no}, tmux: {yes/no})
```

If any step fails for a branch, report the error but continue with the next branch.

---

## Phase 6: Prune and Verify

### Step 1: Prune

```bash
git -C "${WORKTREE_REPO_PATH}" fetch --prune
git -C "${WORKTREE_REPO_PATH}" worktree prune
```

### Step 2: Show Final State

```bash
echo "=== Remaining Worktrees ==="
git -C "${WORKTREE_REPO_PATH}" worktree list

echo "=== Remaining Local Branches ==="
git -C "${WORKTREE_REPO_PATH}" branch

echo "=== Remaining Remote Branches ==="
git -C "${WORKTREE_REPO_PATH}" branch -r
```

### Step 3: Summary

```
## Cleanup Complete

**Cleaned:** {N} branches
**Skipped:** {M} branches
**Errors:** {E} (if any)

### Cleaned
- {branch1}: worktree removed, local deleted, remote deleted, tmux killed
- {branch2}: local deleted, remote deleted

### Remaining
- {X} local branches
- {Y} remote branches
- {Z} worktrees
```

---

## Error Handling

- **`.forge` not found:** Report error, suggest running from the correct directory or creating `.forge`
- **`gh` CLI not authenticated:** Report error, suggest `gh auth login`
- **Worktree remove fails:** Report error for that branch, continue with remaining branches
- **Remote branch already deleted:** Skip silently (not an error)
- **Local branch already deleted:** Skip silently (not an error)
- **Tmux session not found:** Skip silently (not an error)
- **Network errors during `gh` calls:** Report error and suggest retrying

## Important Notes

- **NEVER delete a branch that has an open PR** — this auto-closes the PR on GitHub
- **NEVER delete a branch where the PR author is not the current user** — respect team ownership
- **ALWAYS show the full plan and get explicit approval before any deletion**
- **Protected branches (`main`, `master`, `staging`, `develop`) are NEVER touched**
- **Branches with no PR are listed as "manual review needed" and NEVER auto-deleted**
- **All `git` commands use `git -C` to avoid cwd issues**
- **Continue processing remaining branches if one fails**
- **Tmux kill is per-branch, not a session-ending operation like in `/cleanup`**
