---
description: Promote staging to production with full compliance audit trail
---
# /release - Production Release with SOC2 Compliance

**Prerequisites**: Linear MCP configured, on `staging` or `main` branch, `gh` CLI authenticated.

```
/release
/release --dry-run    # Show what would be released without executing
```

### Phase 1: Pre-flight Checks

**1.1** Verify branch:
```bash
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "staging" && "$CURRENT_BRANCH" != "main" ]]; then
  echo "Must be on staging or main branch to release"
  exit 1
fi
git fetch origin staging main
```

**1.2** Check staging ahead of main:
```bash
COMMITS_AHEAD=$(git rev-list --count origin/main..origin/staging)
if [[ "$COMMITS_AHEAD" -eq 0 ]]; then
  echo "Nothing to release: staging and main are identical"
  exit 0
fi
```

**1.3** Verify CI on staging:
```bash
STAGING_SHA=$(git rev-parse origin/staging)
gh api repos/{owner}/{repo}/commits/$STAGING_SHA/status --jq '.state'
gh api repos/{owner}/{repo}/commits/$STAGING_SHA/check-runs --jq '.check_runs[] | "\(.name): \(.conclusion)"'
```
If not passing: STOP, report failed checks.

**1.4** Check open PRs targeting staging:
```bash
gh pr list --base staging --state open --json number,title,author
```
If any: WARN with table, note these are NOT included.

### Phase 2: Gather Release Contents

**2.1** Commits: `git log origin/main..origin/staging --oneline --no-merges`
**2.2** PRs: Extract PR numbers from merge commits, fetch details via `gh pr view {number} --json number,title,author,mergedAt,url,body`
**2.3** Linear tickets: Extract from commits/PR bodies, fetch via `linear_get_issue(id)`
**2.4** Compliance archives: `git ls-tree -r --name-only origin/compliance-archives compliance/ | grep "pr-{number}"`
**2.5** Change summary: `git diff origin/main..origin/staging --shortstat`

### Phase 3: Build Release Summary

Present comprehensive summary: commits count, PRs included (table with compliance status), Linear tickets (table with status), key changes by area, compliance checklist. Group changes by area (Web, Algorithm, Infrastructure, etc.).

### Phase 4: User Confirmation

**Confirmation word system** — prevent accidental releases:
- Pick random word from: `DEPLOY, RELEASE, SHIP, LAUNCH, PROMOTE, CONFIRM, PROCEED, EXECUTE, AUTHORIZE, APPROVE, PUBLISH, DELIVER, ACTIVATE, ENABLE, GO`
- Never same word twice in a row, case-sensitive
- AskUserQuestion — Header: "Release", Options: "{RANDOM_WORD}" (confirm), "ABORT" (cancel)
- If anything other than exact word: stop immediately

### Phase 5: Execute Release

**5.1** Create release JSON record with: release_id, timestamp, released_by/email, from/to refs+SHAs, commit/file/insertion/deletion counts, pull_requests array (number, title, url, author, merged_at, compliance_archive), linear_tickets array (id, title, url, status), change_summary by area, ci_status, confirmation record.

**5.2** Push to compliance-archives:
```bash
git worktree add /tmp/compliance-archives origin/compliance-archives 2>/dev/null || true
cd /tmp/compliance-archives
git pull origin compliance-archives
mkdir -p releases
RELEASE_BASENAME="release-$(date +%Y-%m-%d)-$(date +%H%M%S)"
```
Write `releases/${RELEASE_BASENAME}.json` and `releases/${RELEASE_BASENAME}.md` (human-readable report with Summary table, From→To, PRs table with compliance archive links, tickets table, changes by area, CI status, confirmation record).
```bash
git add "$RELEASE_JSON" "$RELEASE_MD"
git commit -m "release: $(date +%Y-%m-%d) - {N} PRs, {N} tickets"
git push origin compliance-archives
cd - && git worktree remove /tmp/compliance-archives
```

**5.3** Fast-forward main:
```bash
git checkout main
git merge --ff-only origin/staging
git push origin main
```
If fast-forward fails: STOP — main has diverged. Report and suggest investigating `git log origin/staging..origin/main`. Do NOT force-push.

**5.4** Verify deployment: `gh run list --branch main --limit 1 --json status,conclusion,name,url`

### Phase 6: Post-Release

**6.1** For each ticket: `linear_create_comment(issueId, body: "Released to production in release-{id}\n\nRelease: {archive_url}\nDeploy: {github_actions_url}")`

**6.2** Final report: Release ID, deployment stats, compliance archive location, deployment URLs, Linear update status.

## Dry Run Mode
Execute Phases 1-3 only (checks and summary). Skip 4-6. Report what WOULD happen.

## Error Handling
- **CI not passing**: STOP, report failed checks
- **Nothing to release**: Report staging=main
- **Main diverged**: STOP, report direct pushes to main, suggest investigation
- **Compliance archive missing**: WARN, note gap in audit trail, proceed
- **Linear ticket not found**: WARN, note in audit trail, proceed
