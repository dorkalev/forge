---
description: Clean up a worktree after its PR is merged. Removes worktree, deletes branches, and kills tmux session.
---

# /cleanup - Remove Merged Worktree

You are an automation assistant that safely cleans up worktrees after their PRs have been merged.

## Your Mission

When the user runs `/cleanup`, execute this workflow:

### Step 1: Verify Running in Worktree

Check if the current directory is inside a git worktree:

```bash
COMMON_DIR=$(git rev-parse --git-common-dir 2>/dev/null)
```

If `COMMON_DIR` does NOT contain `/.git/worktrees/`, you are in the main repo, not a worktree:

```
Error: Not in a worktree

This command must be run from inside a worktree directory.
Current directory: {pwd}

Use this command from a worktree created by /issues or /worktree.
```

### Step 2: Gather Worktree Metadata

```bash
# Current branch name
BRANCH=$(git branch --show-current)

# Current worktree path
WORKTREE_PATH=$(pwd)

# Main repo path (strip /.git/worktrees/... suffix)
MAIN_REPO_PATH=$(git rev-parse --git-common-dir | sed 's|/\.git/worktrees/.*||')
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

If no PR found:

```
Error: No PR found for branch {BRANCH}

Cannot verify merge status without a PR.
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

**IMPORTANT:** All cleanup commands must be chained in a single bash invocation. When running from inside a worktree, after `git worktree remove` deletes the directory, the shell's working directory no longer exists. Chaining ensures all commands run in the same session after cd'ing to the main repo.

```bash
cd "${MAIN_REPO_PATH}" && \
  git worktree remove "${WORKTREE_PATH}" && \
  git branch -d "${BRANCH}" && \
  (git ls-remote --heads origin "${BRANCH}" | grep -q "${BRANCH}" && git push origin --delete "${BRANCH}" || echo "Remote branch already deleted") && \
  git worktree prune
```

If the worktree remove fails (e.g., process holding files), report error and suggest:

```
Error: Failed to remove worktree

{error message}

Try:
1. Close any editors/terminals in the worktree
2. Force remove: git worktree remove --force {WORKTREE_PATH}
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
if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
  echo "Killing tmux session: ${SESSION_NAME}"
  tmux kill-session -t "${SESSION_NAME}"
fi
```

## Error Handling

- **Not in worktree:** Clear error with current directory
- **Uncommitted changes:** List files, suggest commit/stash
- **Unpushed commits:** List commits, suggest push command
- **PR not merged:** Show PR URL and current state
- **PR not found:** Suggest checking branch name
- **Worktree remove fails:** Suggest force remove
- **Remote branch gone:** Skip silently (already cleaned)
- **Tmux session gone:** Skip silently (not an error)
- **gh CLI auth error:** Suggest `gh auth login`

## Important Notes

- ALWAYS verify PR is MERGED (not just CLOSED) to prevent data loss
- ALWAYS display success report before killing tmux
- The tmux kill is the absolute last operation
- If any safety check fails, stop immediately and report
