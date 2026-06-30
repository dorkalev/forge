---
description: Create a new Linear issue from a description and set up the full dev environment
---
# /new-issue - Quick Issue Creation

Create a new Linear issue and set up full dev environment (branch, PR, worktree, background agent). Execute steps 1-10 sequentially — do NOT enter plan mode or start implementing. This skill's ONLY job is to create the issue + dev environment; the dispatched Claude background agent in the worktree handles all planning/implementation via `/forge:load`.

**Prerequisites**: Linear MCP configured in `.mcp.json`

```
/new-issue <description>
```

### Step 1: Load Configuration
Read `.forge` for `WORKTREE_REPO_PATH` and `WORKTREE_BASE_PATH`.

### Step 2: Parse Description
Extract from argument. If none, ask user.

### Step 3: Ask About Spec Improvement
AskUserQuestion — Header: "Spec", Options: "Create as-is", "Improve with AI" (quick codebase scan, < 2 min).

### Step 4: Create Issue
**As-is**: Create via Linear MCP with description as title and body.
**Improve with AI**: Brief research (1-2 grep/glob searches), expand into Summary + Requirements + Acceptance Criteria. Then create.

**CRITICAL**: Extract `IDENTIFIER`, `TITLE`, `URL`, and `DESCRIPTION` from the `linear_create_issue` response. Use ONLY the returned identifier — NEVER fabricate or guess an issue ID. Do NOT proceed to Step 5 until the issue is created and you have the real identifier.

### Step 5: Create Branch
```bash
cd "${WORKTREE_REPO_PATH}"
git fetch origin staging
BRANCH_NAME="${IDENTIFIER}-$(echo "${TITLE}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | head -c 50)"
git checkout -b "${BRANCH_NAME}" origin/staging
```

### Step 6: Push Branch
```bash
git push -u origin "${BRANCH_NAME}"
```

### Step 7: Create Draft PR
```bash
gh pr create --draft --head "${BRANCH_NAME}" --base staging \
  --title "${IDENTIFIER}: ${TITLE}" \
  --body "## Linear Issue
| Issue | Title |
|-------|-------|
| [${IDENTIFIER}](${URL}) | ${TITLE} |

## Description
${DESCRIPTION}"
```

### Step 8: Create Worktree
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

### Step 9: Dispatch a Claude Background Agent
```bash
cd "${WORKTREE_PATH}"
claude --bg -n "${IDENTIFIER}" "/forge:load ${IDENTIFIER}"
```
The agent runs `/forge:load` unattended in the worktree, registered under the name `${IDENTIFIER}`. Monitor with `claude agents`, jump in with `claude attach <id>` (Ctrl+Z detaches; it keeps running), peek with `claude logs <id>`.

**Output**: Report Issue ID, Title, Linear URL, Branch, PR URL, Worktree path, and the dispatched background agent name (view with `claude agents`).

## Error Handling
- **Linear MCP not available**: suggest configuring `.mcp.json`
- **No description**: ask user
- **Branch creation fails**: report error

If user starts discussing implementation mid-workflow: capture details for the issue, finish setup, remind them the dispatched background agent handles planning.
