---
description: Start working on a Linear issue — or create a new one. Creates branch, PR, worktree, and dispatches a Claude background agent.
---
# /start - Start Working on a Linear Issue

Read `.forge` for worktree paths:
```bash
WORKTREE_REPO_PATH=$(grep '^WORKTREE_REPO_PATH=' .forge | cut -d= -f2)
WORKTREE_BASE_PATH=$(grep '^WORKTREE_BASE_PATH=' .forge | cut -d= -f2)
```

### Select or Create Issue

**If argument looks like an issue ID** (e.g., `ENG-420`, bare number `123`):
- Fetch via `linear_get_issue`, skip to Create Branch.

**If argument is a description (text, not an ID):**
- Optionally improve spec: briefly scan the codebase (1-2 searches), expand into Summary + Requirements + Acceptance Criteria.
- Create via `linear_create_issue(title, description, teamId)`.
- **CRITICAL**: Extract `IDENTIFIER`, `TITLE`, `URL` from the API response — NEVER fabricate or guess an ID.

**If no argument:**
- Call `linear_get_user_issues(limit: 100)`, sort by priority (1=urgent → 4=low).
- Display as `| ID | Title | Priority | State |` table.
- AskUserQuestion — Header: "Issue", Options: first few issue IDs + "New issue".
- Bare number or `PREFIX-N` → fetch that issue. Anything else → treat as new-issue description.

### Create Branch

```bash
cd "${WORKTREE_REPO_PATH}"
git fetch origin staging
BRANCH_NAME="${IDENTIFIER}-$(echo "${TITLE}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-*$//' | cut -c1-50)"
git checkout -b "${BRANCH_NAME}" origin/staging
git push -u origin "${BRANCH_NAME}"
```

### Ensure Draft PR Exists

```bash
PR_URL=$(gh pr list --head "${BRANCH_NAME}" --base staging --json url --jq '.[0].url // empty')

if [[ -z "${PR_URL}" ]]; then
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
${DESCRIPTION}"
  PR_URL=$(gh pr list --head "${BRANCH_NAME}" --base staging --json url --jq '.[0].url // empty')
else
  echo "PR already exists: ${PR_URL}"
fi
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

### Update Linear & Dispatch Background Agent

Move to "In Progress": `linear_update_issue(issueId, status: "In Progress")`

```bash
cd "${WORKTREE_PATH}"
claude --bg --dangerously-skip-permissions -n "${IDENTIFIER}" "/forge:load ${IDENTIFIER} --unattended"
```

The agent runs unattended in `${WORKTREE_PATH}` and appears in the agent dashboard as `${IDENTIFIER}`.

Manage it with:
- `claude agents` — dashboard of all running agents
- `claude attach <id>` — jump in to watch or steer (Ctrl+Z detaches; agent keeps running)
- `claude logs <id>` — peek at recent output
- `claude stop <id>` — pause (resume with `claude attach <id>`)

**Output**: Report Issue ID, Title, Branch, PR URL, Worktree path, and the dispatched agent name.

## Error Handling
- Linear MCP unavailable → ask user to configure `.mcp.json`
- Branch exists → ask to create worktree for existing branch
- PR exists → skip creation, report existing
- Worktree exists → report and cd to it
