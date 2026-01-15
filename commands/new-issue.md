---
description: Create a new Linear issue from a description and set up the full dev environment
---

# /new-issue - Quick Issue Creation

Create a new Linear issue and instantly set up the full development environment (branch, PR, worktree, tmux).

**Prerequisites**: Linear MCP server must be configured in `.mcp.json`

## CRITICAL: Workflow Guardrails

**DO NOT:**
- Enter plan mode (EnterPlanMode) - this skill IS the planning workflow
- Start implementing features in the current worktree
- Get derailed by user discussion - complete all 10 steps first
- Write code or make changes beyond the issue/spec files

**DO:**
- Execute steps 1-10 sequentially without interruption
- Keep "Improve with AI" research brief (< 2 minutes)
- Create the worktree where ALL planning/implementation will happen
- Hand off to the NEW Claude session in the new worktree

**Remember:** This skill's ONLY job is to create the issue + dev environment. The NEW Claude instance in the worktree will do all planning and implementation via `/forge:load`.

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
  - "Improve with AI" - Quick codebase scan to flesh out requirements (< 2 min)

### Step 4: Create the Issue

**If "Create as-is":**
Use Linear MCP or API to create issue with user's description as both title and description.

**If "Improve with AI":**
Do a BRIEF (< 2 minute) research:
1. Quick grep/glob for related files (1-2 searches max)
2. Identify key files that would be affected
3. Expand description into: Summary, Requirements (bullets), Acceptance Criteria (checkboxes)

**IMPORTANT:** This is NOT deep planning. Just enough context to create a good issue. The real planning happens in the new worktree via `/forge:load`.

Then create the issue with the improved content.

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
  --body "## Linear Issue

| Issue | Title |
|-------|-------|
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
tmux send-keys -t "${SESSION_NAME}" "/load ${IDENTIFIER}" Enter

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

Claude is now running with `/load {IDENTIFIER}` in the new worktree.
```

## Error Handling

- **Linear MCP not available**: Fall back to Linear GraphQL API using credentials from `.forge`
- **No description provided**: Ask user to provide one
- **Branch creation fails**: Report error with details

## Handling User Tangents

If the user starts discussing implementation details, planning, or asks to "plan!" mid-workflow:

1. Acknowledge their input briefly
2. Capture any important details they mentioned for the issue description
3. Remind them: "Let me finish setting up the worktree first - the NEW Claude session there will do the full planning via `/forge:load`"
4. Continue with the remaining steps

**Example response:**
> "Great context! I'll include that in the issue. Let me finish creating the worktree, then the Claude instance there will dive deep into planning with `/forge:load`."
