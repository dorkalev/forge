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

**5.1** Create release JSON record with: release_id, timestamp, released_by/email, from/to refs+SHAs, commit/file/insertion/deletion counts, pull_requests array (number, title, url, author, merged_at, compliance_archive), linear_tickets array (id, title, url, status), change_summary by area, ci_status, confirmation record, release_ticket (added in 5.3).

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

**5.3** Create release ticket in Linear:

Build a product-friendly release summary ticket so the team has a single place to see what shipped.

**Title:** `Release {YYYY-MM-DD} — {N} PRs, {M} tickets`

**Description body** (markdown):
```markdown
## Release Summary

**Date:** {timestamp}
**Commits:** {count}  |  **Files changed:** {count}  |  **+{insertions} / -{deletions}**

## What shipped

| PR | Title | Author |
|----|-------|--------|
| [#{number}]({url}) | {title} | {author} |

## Tickets resolved

| Ticket | Title | Status |
|--------|-------|--------|
| [{id}]({linear_url}) | {title} | {status} |

## Changes by area

{grouped change summary from Phase 3 — e.g., Web, Algorithm, Infrastructure}

## Compliance

- Release archive: `{RELEASE_BASENAME}`
- CI status: {passing/failing}
```

Create via `linear_create_issue()`:
- **teamId**: Use the team from the first Linear ticket gathered in Phase 2 (all tickets in this project share a team)
- **priority**: 0 (None — informational)
- **labelNames**: `["release"]`

Extract `RELEASE_TICKET_ID` and `RELEASE_TICKET_URL` from the response.
**CRITICAL:** Use ONLY the returned identifier — NEVER fabricate ticket IDs.

Update the release JSON (from 5.1) with:
```json
"release_ticket": "{RELEASE_TICKET_ID}",
"release_ticket_url": "{RELEASE_TICKET_URL}"
```

Update the compliance archive files (`releases/${RELEASE_BASENAME}.json` and `.md`) with the ticket reference, then amend the compliance-archives commit:
```bash
git worktree add /tmp/compliance-archives origin/compliance-archives 2>/dev/null || true
cd /tmp/compliance-archives && git pull origin compliance-archives
# Update files with release ticket reference
git add releases/${RELEASE_BASENAME}.json releases/${RELEASE_BASENAME}.md
git commit --amend --no-edit
git push --force-with-lease origin compliance-archives
cd - && git worktree remove /tmp/compliance-archives
```

If Linear MCP is unavailable or ticket creation fails: WARN, skip this step, note gap in audit trail, proceed with release.

**5.4** Fast-forward main:
```bash
git checkout main
git merge --ff-only origin/staging
git push origin main
```
If fast-forward fails: STOP — main has diverged. Report and suggest investigating `git log origin/staging..origin/main`. Do NOT force-push.

**5.5** Verify deployment: `gh run list --branch main --limit 1 --json status,conclusion,name,url`

### Phase 6: Post-Release

**6.1** Mark release ticket Done: If `RELEASE_TICKET_ID` was created in 5.3, call `linear_update_issue(issueId: RELEASE_TICKET_ID)` to set status to "Done".

**6.2** For each ticket: `linear_create_comment(issueId, body: "Released to production in release-{id}\n\nRelease ticket: {RELEASE_TICKET_URL}\nRelease archive: {archive_url}\nDeploy: {github_actions_url}")`

**6.3** Final report: Release ID, release ticket ({RELEASE_TICKET_ID} with URL), deployment stats, compliance archive location, deployment URLs, Linear update status.

## Dry Run Mode
Execute Phases 1-3 only (checks and summary). Skip 4-6. Report what WOULD happen.

## Error Handling
- **CI not passing**: STOP, report failed checks
- **Nothing to release**: Report staging=main
- **Main diverged**: STOP, report direct pushes to main, suggest investigation
- **Compliance archive missing**: WARN, note gap in audit trail, proceed
- **Linear ticket not found**: WARN, note in audit trail, proceed
- **Release ticket creation failed**: WARN, skip ticket step, note gap in audit trail, proceed with release
