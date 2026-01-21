---
description: Show your assigned Linear issues or create a new one. Creates branch, PR, worktree, and opens Claude in tmux with the issue.
---

# /start - Start Working on a Linear Issue

You are an automation assistant that helps developers start working on Linear issues.

**Prerequisites**: Linear MCP server must be configured in `.mcp.json`

## Your Mission

When the user runs `/start`, execute this workflow:

### Step 1: Load Configuration

Read the `.forge` file for worktree paths:

```bash
WORKTREE_REPO_PATH=$(grep '^WORKTREE_REPO_PATH=' .forge | cut -d= -f2)
WORKTREE_BASE_PATH=$(grep '^WORKTREE_BASE_PATH=' .forge | cut -d= -f2)
```

### Step 2: Fetch Assigned Issues

Use the Linear MCP tool to get issues assigned to the current user:

```
linear_get_user_issues(limit: 100)
```

Parse the response and sort by priority (1=urgent, 2=high, 3=medium, 4=low, 0/null=none).

### Step 3: Display Issues and Get Selection

Output all fetched issues in a formatted table:

```
## Your Linear Issues ({count} total)

| ID | Title | Priority | State |
|-----|-------|----------|-------|
| PROJ-123 | Fix login bug | Urgent | In Progress |
| PROJ-124 | Add dark mode | High | Backlog |
...

Enter a PROJ issue ID (e.g., PROJ-125) to work on it,
or type a description to create a new issue.
```

Use AskUserQuestion to get input:
- Header: "Issue"
- Question: "Enter PROJ ID or description for new issue:"
- Options: "PROJ-XXX" and "New issue"
- User will use "Other" to type their input

**Parse the user's input:**
- If matches `^PROJ-\d+$` or `^\d+$`: Treat as existing issue ID
- Otherwise: Treat as new issue description -> go to Step 3b

### Step 3b: Create New Issue

1. Ask about spec improvement with AskUserQuestion:
   - "Create as-is" vs "Improve with AI"

2. **If "Create as-is"**: Use Linear MCP to create issue:
   ```
   linear_create_issue(
     title: "<user input>",
     description: "<user input>",
     teamId: "<from linear_search_issues or known team>"
   )
   ```

3. **If "Improve with AI"**: Research codebase, generate improved spec, then create issue with improved content.

4. Continue from Step 4 with the new issue.

### Step 4: Create Branch

1. Generate branch name: `{identifier}-{slugified-title}` (max 50 chars)
   - Example: `eng-123-fix-login-bug`
   - **IMPORTANT**: Do NOT add any prefix like username, namespace, or folder structure. The branch name must start directly with the issue identifier.

2. Create branch from latest origin/staging:
   ```bash
   cd "${WORKTREE_REPO_PATH}"
   git fetch origin staging
   git checkout -b "${BRANCH_NAME}" origin/staging
   ```

3. **Optional**: Ask if user wants to expand the specification with AI.

4. Create issue file at `issues/{IDENTIFIER}.md`:
   ```markdown
   # {IDENTIFIER}: {Title}

   **Priority:** {priority}
   **State:** {state}
   **URL:** {url}

   ## Description

   {description}

   ## Tasks

   - [ ] Review requirements
   - [ ] Implement solution
   - [ ] Write tests
   - [ ] Update documentation
   ```

5. Commit and push:
   ```bash
   git add "issues/${IDENTIFIER}.md"
   git commit -m "Add issue file for ${IDENTIFIER}"
   git push -u origin "${BRANCH_NAME}"
   ```

### Step 5: Create Draft PR

```bash
gh pr create \
  --draft \
  --head "${BRANCH_NAME}" \
  --base staging \
  --title "${IDENTIFIER}: ${TITLE}" \
  --body "## Linear Issue

| Issue | Title |
|-------|-------|
| [${IDENTIFIER}](${URL}) | ${TITLE} |

## Description

${DESCRIPTION}"
```

### Step 6: Create Worktree

```bash
WORKTREE_PATH="${WORKTREE_BASE_PATH}/${BRANCH_NAME}"
cd "${WORKTREE_REPO_PATH}"
git worktree add -B "${BRANCH_NAME}" "${WORKTREE_PATH}" "origin/${BRANCH_NAME}"

# Setup environment
cp "${WORKTREE_REPO_PATH}/.env" "${WORKTREE_PATH}/.env" 2>/dev/null || true
cp -r "${WORKTREE_REPO_PATH}/.claude" "${WORKTREE_PATH}/.claude" 2>/dev/null || true
ln -sf "${WORKTREE_REPO_PATH}/.forge" "${WORKTREE_PATH}/.forge"
ln -sf "${WORKTREE_REPO_PATH}/.mcp.json" "${WORKTREE_PATH}/.mcp.json"

cd "${WORKTREE_PATH}" && git submodule update --init --recursive 2>/dev/null || true
```

### Step 7: Update Linear Issue State

Use Linear MCP to move issue to "In Progress":
```
linear_update_issue(issueId: "<id>", status: "In Progress")
```

### Step 8: Open Tmux with Claude

```bash
SESSION_NAME="${IDENTIFIER}"
tmux new-session -d -s "${SESSION_NAME}" -c "${WORKTREE_PATH}"
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

## Output Format

```
## Issue Started: {IDENTIFIER}

**Branch:** {BRANCH_NAME}
**PR:** {PR_URL}
**Worktree:** {WORKTREE_PATH}
**Tmux Session:** {SESSION_NAME}

Claude is now running with `/forge:load {IDENTIFIER}` in the new worktree.
```

## Error Handling

- If Linear MCP not available: Report error, ask user to configure `.mcp.json`
- If branch exists: Ask user if they want to create worktree for existing branch
- If PR exists: Skip PR creation, report existing PR
- If worktree exists: Report it and cd to it
