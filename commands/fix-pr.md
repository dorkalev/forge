---
description: Auto-fix code review findings in continuous loop
---

# /fix-pr - Auto-Fix Code Review Findings

You are an automated Code Review Fixer. Your mission is to fix findings from both:
1. **`/code-review`** - Claude's multi-agent review (local)
2. **CodeRabbit** - GitHub bot review (remote)

**Prerequisites**:
- `gh` CLI must be authenticated (`gh auth login`)
- `/code-review` plugin: `/plugin add anthropics/claude-plugins-official/plugins/code-review`
- CodeRabbit enabled on the repository (GitHub app)

## Usage

```
/fix-pr
```

Run this to start the automated fix loop for all review findings.

## Workflow

### Phase 1: Setup

1. Get current branch: `git branch --show-current`
2. Find the PR:
   ```bash
   gh pr list --head <branch> --base staging --json number,url,title,isDraft
   ```
3. If PR is draft, convert to ready:
   ```bash
   gh pr ready <pr-number>
   ```

### Phase 2: Run Local Code Review

Run `/code-review` to trigger Claude's multi-agent review.

This runs 5 parallel agents checking:
- CLAUDE.md compliance
- Obvious bugs in changes
- Git history context
- Previous PR comments
- Code comment compliance

Only issues scoring 80+ confidence are surfaced.

### Phase 3: Fetch All Review Comments

Get comments from both sources:

**Claude /code-review comments:**
```bash
gh pr view <pr-number> --comments --json comments
```
Look for comments starting with `### Code review`.

**CodeRabbit comments:**
```bash
gh api repos/{owner}/{repo}/pulls/{pr-number}/comments
```
Filter for comments from `coderabbitai[bot]`.

Also fetch review body:
```bash
gh api repos/{owner}/{repo}/pulls/{pr-number}/reviews
```

### Phase 4: Parse and Prioritize

**CodeRabbit severity markers:**
- **Critical**: `_Critical_` - MUST fix
- **Major**: `_Major_` or `Potential issue` - MUST fix
- **Minor**: `_Minor_` - skip
- **Trivial**: `_Trivial_` or `Nitpick` - skip

**/code-review issues:**
- All surfaced issues are high-confidence (80+) - fix all

**Categorize:**
- **Bug/Fix Required**: Clear problem with solution
- **Design Question**: Asks for confirmation ("confirm whether", "is this acceptable")

### Phase 5: Fix Issues

For each issue:

1. Read the linked file and line range
2. Understand the problem from the description
3. Apply the fix
4. Verify syntax is valid

**For design questions - present to user:**
```
Issue: {description}
Source: {CodeRabbit | /code-review}
File: {file}:{line}

[A] Acknowledge (keep as-is)
[F] Fix it
[S] Skip
```

### Phase 6: Commit and Push

```bash
git add -A
git status --porcelain
# If changes:
git commit -m "fix: address code review findings

- [list each fix]"
git push
```

### Phase 7: Reply to CodeRabbit Comments

For each fixed CodeRabbit comment, reply:
```bash
gh api repos/{owner}/{repo}/pulls/{pr-number}/comments/{commentId}/replies \
  -f body="Fixed in commit {hash} - {description}"
```

For acknowledged design questions:
```bash
gh api repos/{owner}/{repo}/pulls/{pr-number}/comments/{commentId}/replies \
  -f body="Acknowledged - {explanation}"
```

### Phase 8: Wait and Repeat

1. Display: "Waiting 3 minutes for CodeRabbit to re-review..."
2. Sleep 180 seconds
3. Go back to Phase 2

## Stopping the Loop

The loop continues until:
- No more Major/Critical issues from either source
- User presses Ctrl+C or types "stop"
- GitHub API returns errors

## Quality Rules

1. **Only fix Major and Critical** from CodeRabbit - skip Minor/Trivial
2. **Fix all** from /code-review (already filtered to 80+ confidence)
3. **Verify syntax** after editing
4. **Preserve functionality** - fixes should not change intended behavior
5. **Atomic commits** - focused and reversible
6. **Clear messages** - list what was fixed

## Example Session

```
Starting code review fix loop for PR #44

[Iteration 1]
Running /code-review...
Fetching CodeRabbit comments...

Found issues:
  /code-review: 2 issues
  CodeRabbit: 4 (2 Major, 2 Minor - skipping Minor)

Fixing:
  1. [/code-review] Missing error handling -> Added try/catch
  2. [/code-review] Memory leak -> Added cleanup in finally
  3. [CodeRabbit Major] innerHTML XSS -> Replaced with DOM construction
  4. [CodeRabbit Major] SQL injection -> Parameterized query

Design questions (need your input):
  5. [CodeRabbit] "Confirm cartesian product pattern is acceptable"
     [A] Acknowledge  [F] Fix it  [S] Skip

User: A - needed for multi-date comparison

Committed: abc1234
Replied to CodeRabbit comments
Waiting 3 minutes...

[Iteration 2]
Running /code-review... No issues found.
Fetching CodeRabbit comments... No Major/Critical remaining.

All reviews complete!
```

## Error Handling

- **API rate limit**: Wait and retry
- **File not found**: Skip, report, continue
- **Parse error**: Log raw response, skip, continue
- **Git conflict**: Stop, report, await instruction
- **Network error**: Retry 3x with backoff, then stop
