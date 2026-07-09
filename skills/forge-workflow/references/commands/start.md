---
description: Show your assigned Linear issues or create a new one. Creates branch, PR, worktree, then implements the issue in the current session.
---
# /start - Start Working on a Linear Issue

Read `.forge` for worktree paths:
```bash
WORKTREE_REPO_PATH=$(grep '^WORKTREE_REPO_PATH=' .forge | cut -d= -f2)
WORKTREE_BASE_PATH=$(grep '^WORKTREE_BASE_PATH=' .forge | cut -d= -f2)
```

### Select Issue
**If argument is an issue ID** (e.g., `PROJ-420`), fetch via Linear MCP, skip to Create Branch.

**Otherwise**, `linear_get_user_issues(limit: 100)`, sort by priority (1=urgent → 4=low), display as `| ID | Title | Priority | State |` table. AskUserQuestion — Header: "Issue", Question: "Enter issue ID or description for new issue", Options: "PROJ-XXX" and "New issue".
- Matches `^PROJ-\d+$` or `^\d+$` → fetch that issue
- Otherwise → this is a new issue description. Optionally improve spec with AI first. Then call `linear_create_issue` and **extract the identifier from the API response** (e.g., `PROJ-123`). Use ONLY this returned identifier for all subsequent steps — NEVER fabricate or guess an issue ID.

### Create Branch
1. Name: `{identifier}-{slugified-title}` (max 50 chars). **No prefix** — starts with issue identifier.
2. Create from staging:
   ```bash
   cd "${WORKTREE_REPO_PATH}"
   git fetch origin staging
   git checkout -b "${BRANCH_NAME}" origin/staging
   ```
3. Push branch:
   ```bash
   git push -u origin "${BRANCH_NAME}"
   ```

### Ensure Draft PR Exists
```bash
PR_URL=$(gh pr list --head "${BRANCH_NAME}" --base staging --json url --jq '.[0].url // empty')

if [[ -z "${PR_URL}" ]]; then
  cat > /tmp/forge_pr_body.md <<EOF
## Linear Tickets

| Ticket | Title | Status |
|--------|-------|--------|
| [${IDENTIFIER}](${URL}) | ${TITLE} | In Progress |

---
## Description
${DESCRIPTION}

---
*Run /forge:finish to build comprehensive compliance document.*
EOF

  gh pr create \
    --draft \
    --head "${BRANCH_NAME}" \
    --base staging \
    --title "${IDENTIFIER}: ${TITLE}" \
    --body-file /tmp/forge_pr_body.md

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

### Update Linear & Implement in This Session
Move to "In Progress": `linear_update_issue(issueId: "<id>", status: "In Progress")`

Report Issue ID, Branch, PR URL, and Worktree path. Then continue the work **in this session** — do NOT shell out to the `claude` CLI or dispatch a background agent. Run the `/forge:load ${IDENTIFIER}` flow here, doing all file edits and git commands inside `${WORKTREE_PATH}`.

## Error Handling
- Linear MCP unavailable → ask user to configure `.mcp.json`
- Branch exists → ask to create worktree for existing branch
- PR exists → skip creation, report existing
- Worktree exists → report and cd to it
