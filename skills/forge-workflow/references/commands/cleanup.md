---
description: Clean up a worktree after its PR is merged. Removes worktree, deletes branches, and kills tmux session. When run from main repo, discovers all your merged branches for bulk cleanup.
---
# /cleanup - Remove Merged Worktree or Bulk-Clean Merged Branches

### Step 1: Detect Context

```bash
if [ -f .git ]; then
  cat .git  # file = worktree → go to WORKTREE MODE (Step 2)
elif [ -d .git ]; then
  echo "Main repo detected → BRANCH CLEANUP MODE (Step 10)"
else
  echo "Error: Not a git repository."
fi
```

---

## WORKTREE MODE (run from inside a worktree)

### Step 2: Gather Metadata
```bash
BRANCH=$(git branch --show-current)
WORKTREE_PATH=$(pwd)
MAIN_REPO_PATH=$(cat .git | sed 's|gitdir: ||' | sed 's|/\.git/worktrees/.*||')
```

### Step 3: Safety Checks (fail on first error)

**Uncommitted changes**: `git status --porcelain` — if non-empty: stop, show status, suggest commit/stash.

**Unpushed commits**: `git fetch origin && git log origin/${BRANCH}..HEAD --oneline` — if non-empty: stop, show commits, suggest push.

**PR is merged**:
```bash
PR_DATA=$(gh pr view ${BRANCH} --json state,url 2>&1)
STATE=$(echo "$PR_DATA" | jq -r '.state')
```
If no PR or gh fails: stop, suggest `gh auth login`. If state != MERGED: stop, show PR URL and state. Cleanup only allowed after merge.

### Step 4: Execute Cleanup

**CRITICAL**: After deletion, cwd is invalid. Use `git -C` for all subsequent commands. Store variables before deletion.

```bash
cd "${MAIN_REPO_PATH}" && \
  git worktree remove "${WORKTREE_PATH}" --force && \
  rm -rf "${WORKTREE_PATH}" && \
  git branch -D "${BRANCH}" 2>/dev/null; \
  git -C "${MAIN_REPO_PATH}" worktree prune
```
Delete remote: `git -C "${MAIN_REPO_PATH}" push origin --delete "${BRANCH}" 2>/dev/null || echo "Remote branch already deleted"`

If worktree remove fails: suggest closing editors in the worktree, then force remove.

### Step 5: Report Success (BEFORE killing tmux)
Report: branch, worktree removed, local+remote branch deleted, now in main repo.

### Step 6: Kill Tmux Session (LAST)
**MUST be last** — killing session may terminate agent.
```bash
tmux kill-session -t "${BRANCH}" 2>/dev/null || true
```

---

## BRANCH CLEANUP MODE (run from main repo)

Discover merged branches that belong to the current user and offer to delete them.

### ⚠️ ABSOLUTE SAFETY RULE — READ THIS FIRST

**You MUST NEVER show or delete branches belonging to other users. Only the current authenticated GitHub user's branches are eligible. Violating this rule destroys other people's work. There is no undo.**

### Step 10: Identify Current User

```bash
CURRENT_USER=$(gh api user --jq .login)
```
If `gh` fails: stop, suggest `gh auth login`. Display: "Scanning branches for GitHub user: **${CURRENT_USER}**"

### Step 11: Fetch and Enumerate Branches

```bash
git fetch --prune
```

**11a — Local branches** (exclude protected):
```bash
git branch --format='%(refname:short)' | grep -vE '^(main|master|staging|develop)$'
```

**11b — Remote branches** (exclude protected):
```bash
git branch -r --format='%(refname:short)' | grep '^origin/' | sed 's|^origin/||' | grep -vE '^(main|master|staging|develop|HEAD)$'
```

Merge both lists into a unique set of branch names.

### Step 12: Get Open PRs (exclusion set)

```bash
gh pr list --state open --json headRefName,number,title,author --limit 200
```
Build an exclusion set of branch names that have open PRs. These are NEVER touched (deleting the branch auto-closes the PR).

### Step 13: Check Each Branch

For each branch from Step 11, skip if it's in the open-PR exclusion set from Step 12. Then query:

```bash
gh pr list --state all --head "${BRANCH}" --json number,state,title,url,author --limit 1
```

**Classify each branch:**

| Condition | Classification |
|-----------|---------------|
| No PR found | Skip — "No PR found (manual review needed)" |
| PR author `.login` ≠ `CURRENT_USER` | Skip — "Not your branch" |
| PR state = OPEN | Skip — "Open PR" |
| PR state = CLOSED (not merged) | Skip — "PR closed without merge" |
| PR state = MERGED AND author = CURRENT_USER | **Cleanable** |

**CRITICAL CHECK — author filtering**: The `author.login` field from the PR JSON **MUST** match `CURRENT_USER` exactly. If there is no author field, or it doesn't match, the branch is **SKIPPED**. Never assume ownership. When in doubt, skip.

### Step 14: Check Worktree and Dirty State for Cleanable Branches

For each cleanable branch, check if it has an associated worktree:
```bash
git worktree list --porcelain | grep -A2 "branch refs/heads/${BRANCH}"
```

If a worktree exists for the branch, check cleanliness:
```bash
git -C "${WORKTREE_PATH}" status --porcelain
git -C "${WORKTREE_PATH}" log origin/${BRANCH}..HEAD --oneline 2>/dev/null
```
If dirty (uncommitted changes or unpushed commits): move to Skip — "Dirty worktree".

### Step 15: Present Cleanup Plan

Display the authenticated user and repo, then two tables:

**Will Clean Up:**

| Branch | PR | Local | Remote | Worktree | Action |
|--------|----|-------|--------|----------|--------|
| BOL-123-feature | #45 (merged) | Yes | Yes | /path/to/wt | Delete all |

**Skipped (will NOT touch):**

| Branch | Reason | Details |
|--------|--------|---------|
| BOL-456-other | Not your branch | PR #78 by other-user |
| BOL-789-wip | Open PR | PR #90 |

If nothing is cleanable: report "No merged branches found for **${CURRENT_USER}**. Nothing to clean up." and exit.

### Step 16: User Approval

AskUserQuestion — Header: "Cleanup", Question: "Review the cleanup plan above. Proceed with deleting these branches?", Options: "Execute cleanup", "Cancel".

If user cancels: exit. If custom input: adjust plan and re-present.

### Step 17: Execute Cleanup

For each approved branch:
```bash
# 1. Remove worktree (if exists)
WORKTREE_PATH=$(git worktree list --porcelain | grep -B1 "branch refs/heads/${BRANCH}" | head -1 | sed 's/^worktree //')
if [ -n "${WORKTREE_PATH}" ]; then
  git worktree remove "${WORKTREE_PATH}" --force
  rm -rf "${WORKTREE_PATH}" 2>/dev/null
fi
# 2. Delete local branch
git branch -D "${BRANCH}" 2>/dev/null
# 3. Delete remote branch
git push origin --delete "${BRANCH}" 2>/dev/null
# 4. Kill tmux session (try both branch name and issue ID)
tmux kill-session -t "${BRANCH}" 2>/dev/null || true
ISSUE_ID=$(echo "${BRANCH}" | grep -oE '^[A-Za-z]+-[0-9]+' | tr '[:lower:]' '[:upper:]')
[ -n "${ISSUE_ID}" ] && tmux kill-session -t "${ISSUE_ID}" 2>/dev/null || true
```
Report progress per branch. Continue on errors.

### Step 18: Prune and Verify
```bash
git fetch --prune
git worktree prune
```
Show remaining local branches, remote branches. Report summary: cleaned count, skipped count, any errors.

---

## Error Handling
- Not a git repo → report cwd
- `gh` not authenticated → suggest `gh auth login`
- Uncommitted changes → list, suggest commit/stash
- Unpushed commits → list, suggest push
- PR not merged → show URL and state
- Worktree remove fails → suggest closing editors, then force
- Remote branch already gone → skip silently
- Tmux session gone → skip silently
- Shell cwd broken after worktree removal → use `git -C`

## Important Rules
- **NEVER** delete a branch with an open PR (auto-closes it)
- **NEVER** delete branches owned by other users — filter by `author.login == CURRENT_USER`
- **Protected branches** (`main`, `master`, `staging`, `develop`) are NEVER touched
- **No-PR branches** are "manual review needed", NEVER auto-deleted
- All `git` commands use `git -C` when cwd may be invalid
- Always present plan and get explicit approval before any deletion
