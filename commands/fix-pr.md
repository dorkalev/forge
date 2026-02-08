---
description: Fix CodeRabbit findings from GitHub PR
---
# /fix-pr - Fix CodeRabbit Findings

Fetch CodeRabbit review comments from GitHub PR and fix Major/Critical issues in a loop.

**Prerequisites**: GitHub token in `.forge`, CodeRabbit enabled on repo.

### Phase 1: Setup
1. `git branch --show-current`
2. Find PR: `gh pr list --head {owner}:{branch} --base staging --json number,url`

### Phase 2: Fetch CodeRabbit Comments
```bash
# Inline review comments
gh api repos/{owner}/{repo}/pulls/{pr-number}/comments
# Issue comments (main thread)
gh api repos/{owner}/{repo}/issues/{pr-number}/comments
```
Filter `coderabbitai[bot]`. Severity: `_Critical_`/`**Critical**` and `_Major_`/`**Major**`/`Potential issue` → MUST fix. `_Minor_`/`_Trivial_`/`Nitpick` → skip. If none found, report success and exit.

### Phase 3: Fix Issues

For each Major/Critical issue, show clear explanation: file:line, problem, root cause, fix applied, code change (before/after). Then:
1. Read affected file
2. Apply fix
3. Verify syntax

**For design questions** ("confirm whether", "is this acceptable"):
Ask user — Options: [A] Acknowledge (keep, reply explaining), [F] Fix it, [S] Skip.

### Phase 4: Commit and Push
```bash
git add -A
git commit -m "fix: address CodeRabbit findings

- [list each fix]"
git push
```

### Phase 5: Reply to Comments
Reply to each fixed comment: `Fixed in commit {hash}`. For acknowledged issues, reply with explanation.

### Phase 5.5: Resolve Review Threads
```bash
gh api graphql -f query='query { repository(owner: "{owner}", name: "{repo}") {
  pullRequest(number: {pr-number}) { reviewThreads(first: 100) { nodes {
    id isResolved comments(first: 1) { nodes { path } } } } } } }'
```
For each addressed unresolved thread:
```bash
gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "{id}"}) { thread { isResolved } } }'
```

### Phase 6: Wait for Re-review
Poll every 30s (max 10 min) until CodeRabbit finishes:
```bash
gh pr view {pr-number} --json comments \
  --jq '.comments | map(select(.author.login == "coderabbitai")) | .[-1].body' \
  | grep -q "Currently processing"
```
Once done, re-fetch comments. **Repeat entire workflow** if new Critical/Major issues found.

## Stopping
Loop stops when: no Major/Critical remain, user types "stop", or GitHub API errors after 3 retries.

## Error Handling
- **API rate limit**: Wait 60s, retry | **File not found**: Skip, continue
- **Git conflict**: STOP, await user | **Network error**: Retry 3x, then stop
- **CodeRabbit timeout** (10+ min): Ask user to continue waiting or proceed
