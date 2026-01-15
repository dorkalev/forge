---
description: Clean up a worktree after its PR is merged. Removes worktree, deletes branches, and kills tmux session.
---

# /cleanup - Remove Merged Worktree

You are an automation assistant that safely cleans up worktrees after their PRs have been merged.

## Your Mission

When the user runs `/cleanup`, execute this workflow:

### Step 1: Verify Running in Worktree

Check if the current directory is inside a git worktree by examining the `.git` entry:

```bash
if [ -f .git ]; then
  echo "In worktree"
  cat .git
else
  echo "Not in worktree"
fi
```

In a worktree, `.git` is a **file** containing `gitdir: /path/to/main/.git/worktrees/branch-name`.
In the main repo, `.git` is a **directory**.

If `.git` is NOT a file:

```
Error: Not in a worktree

This command must be run from inside a worktree directory.
Current directory: {pwd}

Use this command from a worktree created by /start or /worktree.
```

### Step 2: Gather Worktree Metadata

```bash
# Current branch name
BRANCH=$(git branch --show-current)

# Current worktree path
WORKTREE_PATH=$(pwd)

# Main repo path - extract from the .git file's gitdir pointer
# The .git file contains: gitdir: /path/to/main/.git/worktrees/branch-name
MAIN_REPO_PATH=$(cat .git | sed 's|gitdir: ||' | sed 's|/\.git/worktrees/.*||')
```

Report what was detected:

```
Detected worktree:
- Branch: {BRANCH}
- Worktree: {WORKTREE_PATH}
- Main repo: {MAIN_REPO_PATH}
```

### Step 3: Safety Checks

Run ALL checks before proceeding. Fail on the first error.

**Check 1: Uncommitted Changes**

```bash
STATUS=$(git status --porcelain)
```

If non-empty:

```
Error: Uncommitted changes exist

Cannot cleanup with uncommitted changes:

{STATUS}

Please commit or stash changes first.
```

**Check 2: Unpushed Commits**

```bash
git fetch origin
UNPUSHED=$(git log origin/${BRANCH}..HEAD --oneline 2>/dev/null)
```

If non-empty:

```
Error: Unpushed commits exist

Cannot cleanup with unpushed commits:

{UNPUSHED}

Please push commits first: git push origin {BRANCH}
```

**Check 3: PR is Merged**

```bash
PR_DATA=$(gh pr view ${BRANCH} --json state,url 2>&1)
```

If no PR found or gh CLI fails:

```
Error: No PR found for branch {BRANCH}

Cannot verify merge status without a PR.
If gh CLI auth failed, run: gh auth login
```

Parse state:

```bash
STATE=$(echo "$PR_DATA" | jq -r '.state')
URL=$(echo "$PR_DATA" | jq -r '.url')
```

If state is NOT `MERGED`:

```
Error: PR is not merged (state: {STATE})

PR: {URL}
Cleanup only allowed after PR is merged to prevent data loss.
```

Report all checks passed:

```
Safety checks passed:
- No uncommitted changes
- No unpushed commits
- PR is merged
```

### Step 4: Execute Cleanup

**CRITICAL:** After deleting the worktree directory, the shell's working directory becomes invalid. All subsequent commands MUST use `git -C "${MAIN_REPO_PATH}"` to avoid "path does not exist" errors.

**IMPORTANT:** Store all variables before deletion since we can't read `.git` file after removal.

Execute cleanup in a single chained command:

```bash
cd "${MAIN_REPO_PATH}" && \
  git worktree remove "${WORKTREE_PATH}" --force && \
  rm -rf "${WORKTREE_PATH}" && \
  git branch -D "${BRANCH}" 2>/dev/null; \
  git -C "${MAIN_REPO_PATH}" worktree prune
```

Then delete remote branch (use `git -C` since cwd may be invalid):

```bash
git -C "${MAIN_REPO_PATH}" push origin --delete "${BRANCH}" 2>/dev/null || echo "Remote branch already deleted or not found"
```

If the worktree remove fails (e.g., process holding files), report error and suggest:

```
Error: Failed to remove worktree

{error message}

Try:
1. Close any editors/terminals in the worktree
2. Force remove: git worktree remove --force {WORKTREE_PATH}
```

**Recovery if shell cwd is broken:**

If subsequent bash commands fail with "Path ... does not exist", the shell session's working directory is invalid. Use this pattern for all remaining commands:

```bash
git -C "${MAIN_REPO_PATH}" <command>
```

Or spawn a fresh shell:

```bash
/bin/zsh -c 'cd /path/to/main && git <command>'
```

### Step 5: Report Success

Display the success report BEFORE killing tmux:

```
## Cleanup Complete

**Branch:** {BRANCH}
**Worktree:** {WORKTREE_PATH} (removed)
**Local Branch:** Deleted
**Remote Branch:** Deleted

You are now in the main repo: {MAIN_REPO_PATH}
```

### Step 6: Kill Tmux Session (LAST)

**IMPORTANT:** This step MUST be last. If the agent is running inside this tmux session, killing it will terminate the agent. All cleanup work must be complete before this step.

```bash
SESSION_NAME="${BRANCH}"
tmux kill-session -t "${SESSION_NAME}" 2>/dev/null || echo "No tmux session to kill"
```

## Error Handling

- **Not in worktree:** Clear error with current directory
- **Uncommitted changes:** List files, suggest commit/stash
- **Unpushed commits:** List commits, suggest push command
- **PR not merged:** Show PR URL and current state
- **PR not found:** Suggest checking branch name or gh auth
- **Worktree remove fails:** Suggest force remove
- **Shell cwd broken:** Use `git -C` or `/bin/zsh -c` pattern
- **Remote branch gone:** Skip silently (already cleaned)
- **Tmux session gone:** Skip silently (not an error)
- **gh CLI auth error:** Suggest `gh auth login`

## Important Notes

- ALWAYS verify PR is MERGED (not just CLOSED) to prevent data loss
- ALWAYS display success report before killing tmux
- The tmux kill is the absolute last operation
- If any safety check fails, stop immediately and report
- Use `git -C` for commands after worktree deletion to avoid cwd issues
- Use `git branch -D` (force) since PR merge is already verified
