---
description: Create a git worktree for an existing branch. Use this when the branch already exists and you just need a worktree.
---

# /worktree - Create Worktree for Existing Branch

You are an automation assistant that creates git worktrees for existing branches.

## Usage

```
/worktree {issue-id-or-branch}
```

Examples:
- `/worktree PROJ-248` - Creates worktree for branch matching PROJ-248
- `/worktree proj-248-general-events` - Creates worktree for specific branch

## Your Mission

### Step 1: Load Configuration

Read the `.forge` file:

```bash
cat .forge 2>/dev/null
```

Extract:
- `WORKTREE_REPO_PATH` - Git repo to create worktrees from
- `WORKTREE_BASE_PATH` - Directory for worktrees

### Step 2: Find the Branch

If user provided an issue ID (e.g., PROJ-248):
```bash
cd "${WORKTREE_REPO_PATH}"
git fetch origin
git branch -r | grep -i "proj-248"
```

If user provided a branch name, use it directly.

### Step 3: Check if Worktree Already Exists

```bash
git worktree list | grep "${BRANCH_NAME}"
```

If worktree exists, report its path and offer to cd to it.

### Step 4: Create Worktree

```bash
WORKTREE_PATH="${WORKTREE_BASE_PATH}/${BRANCH_NAME}"

cd "${WORKTREE_REPO_PATH}"
git worktree add -B "${BRANCH_NAME}" "${WORKTREE_PATH}" "origin/${BRANCH_NAME}"
```

### Step 5: Setup Environment

```bash
# Copy environment files
cp "${WORKTREE_REPO_PATH}/.env" "${WORKTREE_PATH}/.env" 2>/dev/null || true
cp -r "${WORKTREE_REPO_PATH}/.claude" "${WORKTREE_PATH}/.claude" 2>/dev/null || true

# Symlink .forge
ln -sf "${WORKTREE_REPO_PATH}/.forge" "${WORKTREE_PATH}/.forge"

# Initialize submodules
cd "${WORKTREE_PATH}" && git submodule update --init --recursive 2>/dev/null || true
```

### Step 6: Open Tmux with Claude in New iTerm Window

Extract issue ID from branch name if possible:
```bash
ISSUE_ID=$(echo "${BRANCH_NAME}" | grep -oE '^[A-Za-z]+-[0-9]+' | tr '[:lower:]' '[:upper:]')
```

If issue ID found:
```bash
SESSION_NAME="${BRANCH_NAME}"

# Create tmux session in background
tmux new-session -d -s "${SESSION_NAME}" -c "${WORKTREE_PATH}"
tmux rename-window -t "${SESSION_NAME}" "${ISSUE_ID}"
tmux send-keys -t "${SESSION_NAME}" "claude" Enter
sleep 3
tmux send-keys -t "${SESSION_NAME}" "/ticket ${ISSUE_ID}" Enter

# Open new iTerm window and attach to the tmux session
osascript -e "
tell application \"iTerm\"
    activate
    set newWindow to (create window with default profile)
    tell current session of newWindow
        write text \"tmux attach -t ${SESSION_NAME}\"
    end tell
end tell
"
```

This opens a fresh iTerm window attached to the tmux session where Claude is already running.

## Output Format

```
## Worktree Created

**Branch:** {BRANCH_NAME}
**Path:** {WORKTREE_PATH}
**Tmux Session:** {SESSION_NAME}

Ready to work! Claude is running with `/ticket {ISSUE_ID}`.
```

## Error Handling

- Branch not found: List available branches matching the pattern
- Worktree exists: Report path and ask if user wants to open it
- No issue ID in branch: Just create worktree without Claude auto-prompt
