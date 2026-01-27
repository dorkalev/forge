---
description: Verify PR description covers all Linear tickets from commits (SOC2 compliance)
---

# /verify-pr - PR Description Compliance Verification

You are an elite DevOps Compliance Engineer ensuring complete traceability between code changes and Linear tickets.

**Prerequisites**: Linear MCP server must be configured in `.mcp.json`

## Usage

```
/verify-pr
/verify-pr --fix    # Auto-fix missing tickets and description
```

Run this to verify the PR description is a complete compliance document linking all related Linear tickets.

## Why This Matters (SOC2)

The PR description is the **definitive compliance audit trail**. It must:
- Link ALL Linear tickets referenced in commits
- Explain WHAT changed and WHY
- Enable bidirectional traceability (PR ↔ Linear)

An auditor should be able to look at any merged PR and immediately understand:
1. Which tickets authorized this change
2. What was actually changed
3. Who approved it (via reviews)

## Workflow

### Step 1: Get PR Information

```bash
# Get current branch
BRANCH=$(git branch --show-current)

# Find PR for this branch
gh pr list --head "$BRANCH" --base staging --json number,url,title,body
```

If no PR exists, report error and exit:
```
❌ No PR found for branch: $BRANCH
   Run /forge:pr to create one first.
```

### Step 2: Extract Linear Tickets from Commits

Scan ALL commit messages since staging:

```bash
git log staging..HEAD --format="%s%n%b"
```

Read `.forge` file to get `LINEAR_PROJECTS` (e.g., `VLAD,BACKOFFICE,INFRA,ALGO,XD`).

Build regex patterns dynamically:
- `BOL-\d+` for BACKOFFICE (legacy prefix)
- `VLAD-\d+`, `INFRA-\d+`, `ALGO-\d+`, `XD-\d+`

Extract all unique ticket IDs found in commits.

### Step 3: Extract Tickets from PR Description

Parse the PR body for the Linear Tickets table:

```markdown
## Linear Tickets

| Ticket | Title |
|--------|-------|
| [BOL-123](url) | Title |
```

Extract ticket IDs already documented.

### Step 4: Compare and Report

```
📋 PR Compliance Check: #<pr-number>

TICKETS IN COMMITS:
  ✓ BOL-123 (in PR)
  ✓ BOL-124 (in PR)
  ✗ VLAD-45 (MISSING from PR)

PR DESCRIPTION:
  ✓ Has Linear Tickets table
  ✗ Description section is empty

PR TITLE:
  ✗ Missing ticket ID prefix

CROSS-LINKS:
  ✓ BOL-123 has PR link
  ✓ BOL-124 has PR link
  ✗ VLAD-45 missing PR link
```

### Step 5: Fix Mode (--fix or prompted)

If issues found, ask user:
```
Issues found. Fix automatically?
1. Yes - Update PR and add cross-links
2. No - Just report (I'll fix manually)
```

#### 5a: Add Missing Tickets to PR

For each missing ticket, fetch from Linear:
```
linear_get_issue(id: "<ticket-id>")
```

Build updated ticket table with ALL tickets.

#### 5b: Validate/Request Description

If description is empty or too brief (< 20 words), prompt:
```
PR description is missing or too brief.

The PR description is your compliance audit trail. It should explain:
- What was changed (brief technical summary)
- Why it was changed (business context)
- Any notable decisions or trade-offs

Please provide a PR description (2-5 sentences):
```

#### 5c: Update PR Title

If PR title doesn't include a ticket ID, update it:
```bash
gh pr edit <pr-number> --title "<primary-ticket>: <current-title>"
```

Use the first ticket from commits as primary.

#### 5d: Build and Update PR Body

```markdown
## Linear Tickets

| Ticket | Title |
|--------|-------|
| [BOL-123](https://linear.app/boltx/issue/BOL-123) | Main feature title |
| [BOL-124](https://linear.app/boltx/issue/BOL-124) | Related fix |
| [VLAD-45](https://linear.app/boltx/issue/VLAD-45) | Dashboard update |

## Description

[User-provided or existing description]

## Changes

- [Auto-generated summary of key changes from diff]

---
🤖 Verified by [Forge](https://github.com/dorkalev/forge) compliance workflow
```

Update PR:
```bash
gh pr edit <pr-number> --body "$(cat <<'EOF'
<full-pr-body>
EOF
)"
```

#### 5e: Add Cross-Links to Linear

For each ticket, check if PR is already linked:
```
linear_list_comments(issueId: "<id>")
```

If no comment contains the PR URL, add one:
```
linear_create_comment(issueId: "<id>", body: "🔗 PR: <pr-url>")
```

### Step 6: Final Report

```
✅ PR Compliance Verified

   PR: #123 - BOL-123: Implement feature X
   URL: https://github.com/org/repo/pull/123

   Tickets: 3/3 covered
   - BOL-123: Main feature ✓
   - BOL-124: Related fix ✓
   - VLAD-45: Dashboard update ✓

   Description: Present (147 words)
   Cross-links: 3/3 tickets linked to PR

   Ready for review ✓
```

Or if issues remain:
```
❌ PR Compliance Failed

   Missing from PR: VLAD-45
   Description: Empty

   Run /verify-pr --fix to resolve
```

## Exit Codes

- **Pass**: All tickets covered, description present, cross-links exist
- **Fail**: Missing tickets, empty description, or missing cross-links

When invoked from `/forge:finish`, a failure blocks the workflow.
