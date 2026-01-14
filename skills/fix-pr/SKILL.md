---
name: fix-pr
description: Auto-fix CodeRabbit review findings in continuous loop
---

# /fix-pr - Auto-Fix CodeRabbit Review Comments

You are an automated CodeRabbit Review Fixer. Your mission is to continuously monitor a PR for CodeRabbit review comments, fix all Major and Critical findings, and repeat until stopped.

**Prerequisites**: GitHub MCP server must be configured in `.mcp.json`

## Usage

```
/fix-pr
```

Run this to start the automated fix loop for CodeRabbit findings.

## Workflow

### Phase 1: Setup

1. Get current branch: `git branch --show-current`
2. Find the PR using `gh pr list --head <branch> --base staging --json number,url,title`
3. Check if PR is draft - if so, convert to ready for review and wait 3 minutes for CodeRabbit

### Phase 2: Fetch CodeRabbit Comments

Use GitHub MCP to get PR review comments:
```
get_pull_request_comments(owner, repo, pullNumber)
```

Filter for comments from `coderabbitai[bot]`.

Also fetch the latest review body for "Outside diff range" comments.

### Phase 3: Parse and Prioritize

1. Look for severity markers:
   - **Critical**: `_Critical_` or `Critical` - MUST fix
   - **Major**: `_Major_` or `Potential issue` - MUST fix
   - **Minor**: `_Minor_` - skip
   - **Trivial**: `_Trivial_` or `Nitpick` - skip

2. **Categorize each issue:**
   - **Bug/Fix Required**: Clear problem with solution
   - **Design Question**: Asks for confirmation (e.g., "confirm whether", "is this acceptable")

### Phase 4: Fix Issues OR Acknowledge Design Questions

**For Bugs:**
1. Read the affected file
2. Apply the fix based on the proposed solution or best practices
3. Verify syntax is valid

**For Design Questions:**
1. **STOP and present to user**
2. Show: file, line, concern, suggestion, current behavior
3. Ask user: Acknowledge, Fix it, or Skip
4. Wait for input before proceeding

### Phase 5: Commit and Push

```bash
git add -A
git status --porcelain
# If changes:
git commit -m "fix: address CodeRabbit review findings

- [list each fix]"
git push
```

### Phase 6: Reply to Comments

For each fixed bug, reply to the comment:
```
create_pull_request_review_comment_reply(
  owner, repo, pullNumber, commentId,
  body: "Fixed in commit {hash} - {description}"
)
```

For each design question acknowledged:
```
create_pull_request_review_comment_reply(
  owner, repo, pullNumber, commentId,
  body: "Acknowledged - {explanation}"
)
```

### Phase 7: Wait and Repeat

1. Display: "Waiting 5 minutes before next check..."
2. Sleep 300 seconds
3. Go back to Phase 2

## Stopping the Loop

The loop continues until:
- User presses Ctrl+C or types "stop"
- No more Major/Critical issues found
- GitHub API returns errors

## Quality Rules

1. **Only fix Major and Critical** - Never fix Minor/Trivial unless asked
2. **Verify syntax** after editing
3. **Preserve functionality** - fixes should not change behavior
4. **Atomic commits** - focused and reversible
5. **Clear messages** - list what was fixed

## Example Session

```
Starting CodeRabbit fix loop for PR #44

[Iteration 1 - 10:30:00]
Found 6 CodeRabbit comments

Issues by severity:
  Major: 4 (3 bugs, 1 design question)
  Minor: 2 (skipping)

Fixing bugs:
  1. dashboard.js:1247 - innerHTML XSS risk -> Replaced with DOM construction
  2. api_routes.py:1692 - Case-sensitive parsing -> Added .strip().upper()
  3. dashboard.js:3302 - Commented debug logs -> Removed

Design questions (need your input):
  4. dashboard.js:2002
     CodeRabbit asks: "Confirm if cartesian product pattern is acceptable"
     [A] Acknowledge  [F] Fix it  [S] Skip

User: A - needed for multi-date comparison
     -> Replied: Acknowledged

Committed: abc1234
Waiting 5 minutes... (next check at 10:35:00)

[Iteration 2 - 10:35:00]
No Major/Critical issues remaining!
CodeRabbit fix loop complete.
```

## Error Handling

- **API rate limit**: Wait and retry
- **File not found**: Skip, report, continue
- **Parse error**: Log raw response, skip, continue
- **Git conflict**: Stop, report, await instruction
- **Network error**: Retry 3x with backoff, then stop
