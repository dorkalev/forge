---
description: Fix CodeRabbit, Greptile, and Aikido findings from GitHub PR
---
# /fix-pr - Fix PR Review Findings

Fetch review comments from CodeRabbit, Greptile, and Aikido on the GitHub PR and fix Major/Critical issues using parallel subagents for velocity.

**Prerequisites**: GitHub token in `.forge`, review bots enabled on repo.

### Phase 1: Setup
1. `git branch --show-current`
2. Find PR: `gh pr list --head {owner}:{branch} --base staging --json number,url`

### Phase 2: Fetch & Triage Review Comments

Fetch all review comments in parallel:
```bash
# Run these in parallel:
gh api repos/{owner}/{repo}/pulls/{pr-number}/comments --paginate   # inline review comments
gh api repos/{owner}/{repo}/issues/{pr-number}/comments --paginate  # issue comments (main thread)

# Also fetch unresolved thread IDs (needed for Phase 5.5):
gh api graphql -f query='...' # reviewThreads query
```

Filter by bot login: `coderabbitai[bot]`, `greptile-apps[bot]`, `aikido-pr-checks[bot]`.

**Severity classification:**
- **CodeRabbit**: `_Critical_`/`**Critical**` and `_Major_`/`**Major**`/`Potential issue` → MUST fix. `_Minor_`/`_Trivial_`/`Nitpick` → skip.
- **Greptile**: All findings are treated as Major (no severity labels) → MUST evaluate. Fix if valid, reply with explanation if not.
- **Aikido**: `medium severity` and above → MUST evaluate. Fix if valid, acknowledge if repo-wide concern.

If no actionable findings, report success and exit.

**Build a findings list** with: `{id, thread_id, bot, severity, file, line, title, body}` for each actionable finding.

### Phase 3: Parallel Evaluation & Fix

**Group findings by file** to avoid edit conflicts, then launch parallel Task subagents (subagent_type="general-purpose", use `isolation: "worktree"` is NOT needed — agents edit files directly).

**Launch 2-4 subagents in a SINGLE message**, each handling a disjoint set of files. Each subagent receives:
- The list of findings for its assigned files (full body text, not just titles)
- Instructions to read each file, evaluate if the finding is valid or false positive, and apply fixes
- The project's coding conventions (from CLAUDE.md: exception handling philosophy, etc.)

**Subagent prompt template:**
```
You are fixing PR review findings. For each finding below, read the affected file,
evaluate whether it's VALID (needs fix) or FALSE POSITIVE (explain why), and if valid, apply the fix using the Edit tool.

Return a structured summary:
- finding_id: {id}
- verdict: VALID | FALSE_POSITIVE | ALREADY_FIXED
- explanation: why
- fix_applied: what changed (or why it's not needed)

Findings assigned to you:
[...findings with full body text, file paths, line numbers...]

Rules:
- Read the file before judging. Don't guess.
- Only fix genuine issues. False positives are fine — just explain why.
- Keep fixes minimal. Don't refactor surrounding code.
- Let errors fail loudly — don't add broad exception handling.
- For design questions ("confirm whether", "is this acceptable"), mark as NEEDS_USER_INPUT.
```

**After all subagents return**, collect results. For any findings marked `NEEDS_USER_INPUT`:
Ask user — Options: [A] Acknowledge (keep, reply explaining), [F] Fix it, [S] Skip.

### Phase 4: Commit and Push
```bash
git add -A
git commit -m "fix: address PR review findings

- [list each fix from subagent results]"
git push
```

### Phase 5: Reply to Comments & Resolve Threads

Reply to each addressed finding on the PR:
- Fixed: `Fixed in commit {hash} — {brief description}`
- False positive: Brief explanation of why it's not an issue
- Acknowledged: Explanation of the design decision

Then resolve all addressed threads:
```bash
gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "{id}"}) { thread { isResolved } } }'
```

Also resolve remaining Minor/Trivial/Nitpick threads that don't need fixes.

### Phase 6: Wait for Re-review
Poll every 30s (max 10 min) until CodeRabbit finishes:
```bash
gh pr view {pr-number} --json comments \
  --jq '.comments | map(select(.author.login == "coderabbitai")) | .[-1].body' \
  | grep -q "Currently processing"
```
Once done, re-fetch comments from all three bots. **Repeat entire workflow** if new Critical/Major issues found.

## Stopping
Loop stops when: no Major/Critical remain, user types "stop", or GitHub API errors after 3 retries.

## Error Handling
- **API rate limit**: Wait 60s, retry | **File not found**: Skip, continue
- **Git conflict**: STOP, await user | **Network error**: Retry 3x, then stop
- **CodeRabbit timeout** (10+ min): Ask user to continue waiting or proceed
