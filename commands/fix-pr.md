---
description: Fix code review + CodeRabbit findings in sequence
---

# /fix-pr - Auto-Fix Code Review Findings

You are an automated Code Review Fixer. Your mission is to fix findings sequentially:
1. **First**: `/code-review` (Claude's multi-agent review)
2. **Then**: CodeRabbit (GitHub bot, runs after push)

**Prerequisites**:
- `gh` CLI authenticated (`gh auth login`)
- `/code-review` plugin: `/plugin add anthropics/claude-plugins-official/plugins/code-review`
- CodeRabbit enabled on repository (GitHub app)

## Usage

```
/fix-pr
```

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

---

## Part A: Claude /code-review Loop

### Phase 2: Run /code-review

Run `/code-review` to trigger Claude's multi-agent review.

5 parallel agents check:
- CLAUDE.md compliance
- Obvious bugs in changes
- Git history context
- Previous PR comments
- Code comment compliance

Only issues scoring 80+ confidence are surfaced.

### Phase 3: Fix /code-review Issues

For each issue from `/code-review`:

1. Read the linked file and line range
2. Understand the problem
3. Apply the fix
4. Verify syntax

### Phase 4: Commit, Push, Repeat

```bash
git add -A
git commit -m "fix: address code review findings

- [list each fix]"
git push
```

Re-run `/code-review`. Repeat until "No issues found".

---

## Part B: CodeRabbit Loop (after /code-review is clean)

### Phase 5: Wait for CodeRabbit

After `/code-review` passes, wait for CodeRabbit to review:

```bash
echo "Waiting 3 minutes for CodeRabbit to review..."
sleep 180
```

### Phase 6: Fetch CodeRabbit Comments

```bash
gh api repos/{owner}/{repo}/pulls/{pr-number}/comments
gh api repos/{owner}/{repo}/pulls/{pr-number}/reviews
```

Filter for `coderabbitai[bot]`.

**Severity markers:**
- **Critical**: `_Critical_` - MUST fix
- **Major**: `_Major_` or `Potential issue` - MUST fix
- **Minor**: `_Minor_` - skip
- **Trivial**: `_Trivial_` or `Nitpick` - skip

If no Major/Critical issues, done!

### Phase 7: Fix CodeRabbit Issues

For each Major/Critical issue:

1. Read the affected file
2. Apply the fix
3. Verify syntax

**For design questions** ("confirm whether", "is this acceptable"):
```
Issue: {description}
File: {file}:{line}

[A] Acknowledge (keep as-is)
[F] Fix it
[S] Skip
```

### Phase 8: Commit and Reply

```bash
git add -A
git commit -m "fix: address CodeRabbit findings

- [list each fix]"
git push
```

Reply to each fixed comment:
```bash
gh api repos/{owner}/{repo}/pulls/{pr-number}/comments/{commentId}/replies \
  -f body="Fixed in commit {hash}"
```

### Phase 9: Wait and Repeat

Wait 3 minutes, re-fetch CodeRabbit comments. Repeat until no Major/Critical remain.

---

## Summary Flow

```
/fix-pr
   │
   ├─► /code-review loop
   │      └─► Fix issues → push → repeat until clean
   │
   └─► CodeRabbit loop (only after /code-review passes)
          └─► Wait → fix Major/Critical → push → repeat until clean
```

## Stopping

The loop stops when:
- Both `/code-review` and CodeRabbit report no issues
- User types "stop" or Ctrl+C
- GitHub API errors

## Example Session

```
Starting fix loop for PR #44

=== Part A: /code-review ===

[Iteration 1]
Running /code-review...
Found 2 issues:
  1. Missing error handling -> Added try/catch
  2. Memory leak -> Added cleanup

Committed: abc1234
Running /code-review again...

[Iteration 2]
No issues found. /code-review complete!

=== Part B: CodeRabbit ===

Waiting 3 minutes for CodeRabbit...

[Iteration 1]
Found 3 CodeRabbit comments (2 Major, 1 Minor)
Fixing Major issues:
  1. innerHTML XSS -> Replaced with DOM
  2. SQL injection -> Parameterized

Committed: def5678
Waiting 3 minutes...

[Iteration 2]
No Major/Critical remaining.

All reviews complete!
```

## Error Handling

- **API rate limit**: Wait and retry
- **File not found**: Skip, report, continue
- **Git conflict**: Stop, await instruction
- **Network error**: Retry 3x, then stop
