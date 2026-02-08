---
description: Create a git worktree for an existing branch. Use this when the branch already exists and you just need a worktree.
---
# /worktree - Create Worktree for Existing Branch

```
/worktree {issue-id-or-branch}
/worktree PROJ-248
/worktree proj-248-general-events
```

### Step 1: Load Configuration
Read `.forge` for `WORKTREE_REPO_PATH` and `WORKTREE_BASE_PATH`.

### Step 2: Find Branch
If issue ID: `git -C "${WORKTREE_REPO_PATH}" fetch origin && git branch -r | grep -i "proj-248"`. If branch name: use directly.

### Step 3: Check Existing
`git worktree list | grep "${BRANCH_NAME}"` — if exists, report path and offer to open.

### Step 4: Create Worktree
```bash
WORKTREE_PATH="${WORKTREE_BASE_PATH}/${BRANCH_NAME}"
cd "${WORKTREE_REPO_PATH}"
git worktree add -B "${BRANCH_NAME}" "${WORKTREE_PATH}" "origin/${BRANCH_NAME}"
```

### Step 5: Setup Environment
```bash
cp "${WORKTREE_REPO_PATH}/.env" "${WORKTREE_PATH}/.env" 2>/dev/null || true
cp -r "${WORKTREE_REPO_PATH}/.claude" "${WORKTREE_PATH}/.claude" 2>/dev/null || true
ln -sf "${WORKTREE_REPO_PATH}/.forge" "${WORKTREE_PATH}/.forge"
cd "${WORKTREE_PATH}" && git submodule update --init --recursive 2>/dev/null || true
```

### Step 6: Open Tmux with Claude in iTerm
```bash
ISSUE_ID=$(echo "${BRANCH_NAME}" | grep -oE '^[A-Za-z]+-[0-9]+' | tr '[:lower:]' '[:upper:]')
SESSION_NAME="${BRANCH_NAME}"
FOLDER_NAME=$(basename "${WORKTREE_PATH}")
tmux new-session -d -s "${SESSION_NAME}" -c "${WORKTREE_PATH}"
tmux set-option -t "${SESSION_NAME}" status-left "[${FOLDER_NAME}] "
tmux set-option -t "${SESSION_NAME}" status-left-length 50
tmux rename-window -t "${SESSION_NAME}" "${ISSUE_ID}"
tmux send-keys -t "${SESSION_NAME}" "claude" Enter
sleep 3
tmux send-keys -t "${SESSION_NAME}" "/load ${ISSUE_ID}" Enter

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
If no issue ID in branch name, just create worktree without Claude auto-prompt.

**Output**: Report Branch, Worktree path, Tmux session.

## Error Handling
- Branch not found → list matching branches | Worktree exists → report path, ask to open | No issue ID → skip Claude auto-prompt
