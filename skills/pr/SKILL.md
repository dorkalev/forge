---
name: pr
description: Open the GitHub PR page for the current branch in browser.
---

# /pr - Open Pull Request in Browser

Open the GitHub PR page for the current branch in the default browser.

**Prerequisites**: GitHub MCP server should be configured in `.mcp.json`

## Usage

```
/pr
```

## Your Mission

### Step 1: Get Current Branch

```bash
git branch --show-current
```

If on `staging` or `main`, report error - this should be run from a feature branch.

### Step 2: Get Repository Info

```bash
gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"'
```

### Step 3: Check if PR Exists

Use GitHub MCP to search for an existing PR for this branch:

```
github_search_pull_requests(
  query: "repo:{owner}/{repo} head:{branch_name} is:pr"
)
```

Or fall back to gh CLI:
```bash
gh pr list --head "${BRANCH_NAME}" --json number,url
```

### Step 4: Handle Result

**If PR exists:**
Open in browser:
```bash
gh pr view "${BRANCH_NAME}" --web
```

Report:
```
Opened PR in browser: {PR_URL}
```

**If no PR exists:**
Report:
```
No PR found for branch: {BRANCH_NAME}

To create a PR, use the /issues workflow or create one manually with:
  gh pr create --draft --base staging
```

## Error Handling

- Not on feature branch: Report error
- No PR found: Report that no PR exists (do not create one)
- gh CLI not authenticated: Prompt user to run `gh auth login`
