---
description: Open the GitHub PR page for the current branch in browser.
---

# /pr - Open Pull Request in Browser

Open the GitHub PR page for the current branch in the default browser.

**Prerequisites**: `gh` CLI must be authenticated (`gh auth login`)

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

Use `gh` CLI to search for an existing PR for this branch:
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

Ask with AskUserQuestion:
- Header: "PR"
- Question: "No PR found for this branch. Create one?"
- Options:
  - "Create draft PR" - Create as draft (recommended)
  - "Create ready PR" - Create as ready for review
  - "Skip" - Don't create, just report

**If user chooses to create:**

Extract issue ID from branch name (e.g., `ENG-123` from `eng-123-fix-something`):
```bash
IDENTIFIER=$(echo "${BRANCH_NAME}" | grep -oE '[A-Z]+-[0-9]+' | head -1)
```

Get issue info from Linear (if identifier found):
```bash
# Use Linear MCP to get issue title and URL
```

Create the PR:
```bash
gh pr create \
  --draft \  # or omit for ready PR
  --head "${BRANCH_NAME}" \
  --base staging \
  --title "${IDENTIFIER}: ${ISSUE_TITLE}" \
  --body "## Linear Issue

| Issue | Title |
|-------|-------|
| [${IDENTIFIER}](${ISSUE_URL}) | ${ISSUE_TITLE} |

## Description

${ISSUE_DESCRIPTION}"
```

If no Linear issue found, create simple PR:
```bash
gh pr create \
  --draft \
  --head "${BRANCH_NAME}" \
  --base staging \
  --title "${BRANCH_NAME}"
```

Then open in browser:
```bash
gh pr view "${BRANCH_NAME}" --web
```

Report:
```
Created and opened PR: {PR_URL}
```

## Error Handling

- Not on feature branch: Report error
- gh CLI not authenticated: Prompt user to run `gh auth login`
