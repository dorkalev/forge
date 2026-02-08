---
description: Show your assigned Linear issues or create a new one. Creates branch, PR, worktree, and opens Claude in tmux with the issue.
---
# /start - Start Working on a Linear Issue

Read `.forge` for worktree paths:
```bash
WORKTREE_REPO_PATH=$(grep '^WORKTREE_REPO_PATH=' .forge | cut -d= -f2)
WORKTREE_BASE_PATH=$(grep '^WORKTREE_BASE_PATH=' .forge | cut -d= -f2)
```

### Select Issue
**If argument is an issue ID** (e.g., `BOL-420`), fetch via Linear MCP, skip to Create Branch.

**Otherwise**, `linear_get_user_issues(limit: 100)`, sort by priority (1=urgent → 4=low), display as `| ID | Title | Priority | State |` table. AskUserQuestion — Header: "Issue", Question: "Enter issue ID or description for new issue", Options: "PROJ-XXX" and "New issue".
- Matches `^PROJ-\d+$` or `^\d+$` → fetch that issue
- Otherwise → create via `linear_create_issue`, optionally improve spec with AI first

### Create Branch
1. Name: `{identifier}-{slugified-title}` (max 50 chars). **No prefix** — starts with issue identifier.
2. Create from staging:
   ```bash
   cd "${WORKTREE_REPO_PATH}"
   git fetch origin staging
   git checkout -b "${BRANCH_NAME}" origin/staging
   ```
3. Create `issues/{IDENTIFIER}.md`:
   ```markdown
   # {IDENTIFIER}: {Title}

   **Priority:** {priority}  |  **State:** {state}  |  **URL:** {url}

   ## Summary
   {description}

   ## Acceptance Criteria
   - [ ] {Extract from Linear description or prompt user}

   ## Out of Scope
   - TBD (clarify during implementation)
   ```
4. Optional: offer to expand the specification with AI.
5. Commit and push:
   ```bash
   git add "issues/${IDENTIFIER}.md"
   git commit -m "Add issue file for ${IDENTIFIER}"
   git push -u origin "${BRANCH_NAME}"
   ```

### Create Draft PR
```bash
gh pr create \
  --draft \
  --head "${BRANCH_NAME}" \
  --base staging \
  --title "${IDENTIFIER}: ${TITLE}" \
  --body "## Linear Tickets

| Ticket | Title | Status |
|--------|-------|--------|
| [${IDENTIFIER}](${URL}) | ${TITLE} | In Progress |

---
## Description
${DESCRIPTION}

---
*Run \`/forge:finish\` to build comprehensive compliance document.*"
```

### Create Worktree
```bash
WORKTREE_PATH="${WORKTREE_BASE_PATH}/${BRANCH_NAME}"
cd "${WORKTREE_REPO_PATH}"
git worktree add -B "${BRANCH_NAME}" "${WORKTREE_PATH}" "origin/${BRANCH_NAME}"
cp "${WORKTREE_REPO_PATH}/.env" "${WORKTREE_PATH}/.env" 2>/dev/null || true
cp -r "${WORKTREE_REPO_PATH}/.claude" "${WORKTREE_PATH}/.claude" 2>/dev/null || true
ln -sf "${WORKTREE_REPO_PATH}/.forge" "${WORKTREE_PATH}/.forge"
ln -sf "${WORKTREE_REPO_PATH}/.mcp.json" "${WORKTREE_PATH}/.mcp.json"
cd "${WORKTREE_PATH}" && git submodule update --init --recursive 2>/dev/null || true
```

### Update Linear & Open Tmux
Move to "In Progress": `linear_update_issue(issueId: "<id>", status: "In Progress")`
```bash
SESSION_NAME="${IDENTIFIER}"
FOLDER_NAME=$(basename "${WORKTREE_PATH}")
tmux new-session -d -s "${SESSION_NAME}" -c "${WORKTREE_PATH}"
tmux set-option -t "${SESSION_NAME}" status-left "[${FOLDER_NAME}] "
tmux set-option -t "${SESSION_NAME}" status-left-length 50
tmux send-keys -t "${SESSION_NAME}" "claude" Enter
sleep 3
tmux send-keys -t "${SESSION_NAME}" "/forge:load ${IDENTIFIER}" Enter

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
**Output**: Report Issue ID, Branch, PR URL, Worktree path, Tmux session name.

## Error Handling
- Linear MCP unavailable → ask user to configure `.mcp.json`
- Branch exists → ask to create worktree for existing branch
- PR exists → skip creation, report existing
- Worktree exists → report and cd to it
