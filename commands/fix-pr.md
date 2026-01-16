---
description: Fix CodeRabbit findings from GitHub PR
---

# /fix-pr - Fix CodeRabbit Findings

You are an automated CodeRabbit Fixer. Your mission is to fetch CodeRabbit review comments from the GitHub PR and fix Major/Critical issues.

**Prerequisites**:
- GitHub API access (token in `.forge` file)
- CodeRabbit enabled on repository (GitHub app)

## Usage

```
/fix-pr
```

## Workflow

### Phase 1: Setup

1. Get current branch: `git branch --show-current`
2. Find the PR using GitHub API:
   ```bash
   curl -s -H "Authorization: token $GITHUB_TOKEN" \
     "https://api.github.com/repos/{owner}/{repo}/pulls?head={owner}:{branch}&base=staging"
   ```
3. Extract PR number and URL

### Phase 2: Fetch CodeRabbit Comments

Fetch all review comments from the PR:

```bash
# Get inline review comments
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/{owner}/{repo}/pulls/{pr-number}/comments"

# Get issue comments (main thread)
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/{owner}/{repo}/issues/{pr-number}/comments"
```

Filter for comments from `coderabbitai[bot]`.

**Severity markers:**
- **Critical**: `_Critical_` or `**Critical**` - MUST fix
- **Major**: `_Major_` or `**Major**` or `Potential issue` - MUST fix
- **Minor**: `_Minor_` - skip
- **Trivial**: `_Trivial_` or `Nitpick` - skip

If no Major/Critical issues found, report success and exit.

### Phase 3: Fix CodeRabbit Issues

For each Major/Critical issue:

1. Read the affected file at the specified line
2. Understand the problem from CodeRabbit's description
3. Apply the fix
4. Verify syntax is correct

**For design questions** ("confirm whether", "is this acceptable", "consider whether"):
Ask the user:
```
CodeRabbit asks: {description}
File: {file}:{line}

Options:
[A] Acknowledge (keep as-is, reply explaining why)
[F] Fix it (apply the suggestion)
[S] Skip (don't reply)
```

### Phase 4: Commit and Push

```bash
git add -A
git commit -m "fix: address CodeRabbit findings

- [list each fix applied]"
git push
```

### Phase 5: Reply to Comments

For each fixed issue, reply to the CodeRabbit comment:

```bash
curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/{owner}/{repo}/pulls/{pr-number}/comments/{commentId}/replies" \
  -d '{"body": "Fixed in commit {hash}"}'
```

For acknowledged (kept as-is) issues, reply with the explanation.

### Phase 6: Wait and Repeat

Wait 2-3 minutes for CodeRabbit to re-review after push:

```bash
sleep 150
```

Re-fetch comments and check for new Major/Critical issues. Repeat until none remain.

---

## Summary Flow

```
/fix-pr
   │
   ├─► Fetch CodeRabbit comments from GitHub PR
   │
   ├─► Filter for Major/Critical severity
   │
   ├─► Fix each issue
   │
   ├─► Commit, push, reply to comments
   │
   └─► Wait for re-review, repeat if new issues
```

## Stopping

The loop stops when:
- No Major/Critical CodeRabbit issues remain
- User types "stop" or Ctrl+C
- GitHub API errors after 3 retries

## Example Session

```
Starting CodeRabbit fix loop for PR #44

[Iteration 1]
Fetching CodeRabbit comments...
Found 4 comments (2 Major, 1 Critical, 1 Minor)

Fixing Critical/Major issues:
  1. [Critical] XSS vulnerability in innerHTML -> Using textContent
  2. [Major] Missing null check -> Added optional chaining
  3. [Major] Hardcoded timeout -> Made configurable

Committed: abc1234
Replied to 3 comments.
Waiting for re-review...

[Iteration 2]
Fetching CodeRabbit comments...
No new Major/Critical issues.

CodeRabbit review complete!
```

## Error Handling

- **API rate limit**: Wait 60s and retry
- **File not found**: Skip issue, report, continue
- **Git conflict**: Stop, await user instruction
- **Network error**: Retry 3x, then stop
- **CodeRabbit still processing**: Wait additional 2 minutes
