---
description: Create a new Linear ticket from a description and set up the full dev environment
---

# /new-issue - Quick Issue Creation

Create a new Linear issue and instantly set up the full development environment (branch, PR, worktree, tmux).

**Prerequisites**: Linear MCP server must be configured in `.mcp.json`

## Usage

```
/new-issue <description>
/new-issue Add dark mode toggle to settings page
/new-issue Fix login redirect issue on mobile
```

## Workflow

### Step 1: Load Configuration

Read `.forge` file for worktree paths:
```bash
WORKTREE_REPO_PATH=$(grep '^WORKTREE_REPO_PATH=' .forge | cut -d= -f2)
WORKTREE_BASE_PATH=$(grep '^WORKTREE_BASE_PATH=' .forge | cut -d= -f2)
```

### Step 2: Parse Description

Extract the description from command argument. If none provided, ask the user.

### Step 3: Ask About Spec Improvement

Use AskUserQuestion:
- Header: "Spec"
- Options:
  - "Create as-is" - Use the description exactly
  - "Improve with AI" - Analyze codebase and create detailed requirements

### Step 4: Create the Issue

**If "Create as-is":**
Use Linear MCP:
```
linear_create_issue(
  title: "<user description>",
  description: "<user description>",
  teamId: "<team ID>"
)
```

**If "Improve with AI":**
Research codebase, generate improved spec, then create issue with improved content.

### Step 5: Create Branch

```bash
cd "${WORKTREE_REPO_PATH}"
git fetch origin
git checkout staging && git pull origin staging

BRANCH_NAME="${IDENTIFIER}-$(echo "${TITLE}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | head -c 50)"
git checkout -b "${BRANCH_NAME}"
```

### Step 6: Create Issue File

Write to `issues/{IDENTIFIER}.md`:
```markdown
# {IDENTIFIER}: {Title}

**Priority:** None
**State:** Backlog
**URL:** {url}

## Description

{description}

## Tasks

- [ ] Review requirements
- [ ] Implement solution
- [ ] Write tests
- [ ] Update documentation
```

### Step 7: Commit and Push

```bash
git add "issues/${IDENTIFIER}.md"
git commit -m "Add issue file for ${IDENTIFIER}"
git push -u origin "${BRANCH_NAME}"
git checkout staging
```

### Step 8: Create Draft PR

```bash
gh pr create \
  --draft \
  --base staging \
  --title "${IDENTIFIER}: ${TITLE}" \
  --body "## Linear Ticket

| Ticket | Title |
|--------|-------|
| [${IDENTIFIER}](${URL}) | ${TITLE} |

## Description

${DESCRIPTION}"
```

### Step 9: Create Worktree

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

### Step 10: Open Tmux with Claude

```bash
SESSION_NAME="${BRANCH_NAME}"
tmux new-session -d -s "${SESSION_NAME}" -c "${WORKTREE_PATH}"
tmux rename-window -t "${SESSION_NAME}" "${IDENTIFIER}"
tmux send-keys -t "${SESSION_NAME}" "claude" Enter
sleep 3
tmux send-keys -t "${SESSION_NAME}" "/ticket ${IDENTIFIER}" Enter

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
## Issue Created: {IDENTIFIER}

**Title:** {TITLE}
**Linear:** {URL}
**Branch:** {BRANCH_NAME}
**PR:** {PR_URL}
**Worktree:** {WORKTREE_PATH}

Claude is now running with `/ticket {IDENTIFIER}` in the new worktree.
```

## Error Handling

- **Linear MCP not available**: Report error, ask user to configure `.mcp.json`
- **No description provided**: Ask user to provide one
- **Branch creation fails**: Report error with details
