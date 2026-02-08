---
description: Clean up a worktree after its PR is merged. Removes worktree, deletes branches, and kills tmux session.
---
# /cleanup - Remove Merged Worktree

### Step 1: Verify Running in Worktree
```bash
if [ -f .git ]; then
  cat .git  # file = worktree (gitdir: /path/.git/worktrees/branch)
else
  echo "Error: Not in a worktree. Run from a worktree created by /start or /worktree."
fi
```

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

## Error Handling
- Not in worktree → report cwd | Uncommitted changes → list, suggest commit/stash
- Unpushed commits → list, suggest push | PR not merged → show URL and state
- Worktree remove fails → suggest force | Remote gone → skip silently
- Tmux gone → skip silently | Shell cwd broken → use `git -C` or `/bin/zsh -c`
