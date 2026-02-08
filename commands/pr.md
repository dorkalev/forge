---
description: Open the GitHub PR page for the current branch in browser.
---
# /pr - Open Pull Request in Browser

**Prerequisites**: `gh` CLI authenticated.

### Step 1: Get Branch
`git branch --show-current` — if on `staging` or `main`, report error (run from feature branch).

### Step 2: Check PR
```bash
gh pr list --head "${BRANCH_NAME}" --json number,url
```

### Step 3: Handle Result

**PR exists**: `gh pr view "${BRANCH_NAME}" --web`. Report URL.

**No PR**: AskUserQuestion — Header: "PR", Options: "Create draft PR" (recommended), "Create ready PR", "Skip".

If creating: extract issue ID from branch (`echo "${BRANCH_NAME}" | grep -oE '[A-Z]+-[0-9]+' | head -1`), fetch from Linear if found, then:
```bash
gh pr create \
  --draft \
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
If no Linear issue: `gh pr create --draft --head "${BRANCH_NAME}" --base staging --title "${BRANCH_NAME}"`. Then open in browser.

## Error Handling
- Not on feature branch → report error | gh not authenticated → suggest `gh auth login`
