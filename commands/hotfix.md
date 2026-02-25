---
description: Document a hotfix pushed directly to main and create a backport PR to staging for SOC2 compliance
---
# /hotfix - Post-Hotfix Compliance Remediation

When a direct push to `main` bypasses the normal PR flow (e.g., production incident), this command documents the emergency change and backports it to staging for SOC2 audit compliance.

**Prerequisites**: On `main` branch or know the hotfix commit SHA(s), Linear MCP configured, `gh` CLI authenticated.

```
/hotfix
/hotfix <commit-sha>
```

### Phase 1: Detect Hotfix Commits

**1.1** Find commits on `main` that are NOT on `staging`:
```bash
git fetch origin staging main
git log origin/staging..origin/main --oneline --no-merges
```

**1.2** If no argument provided, present the divergent commits and AskUserQuestion — Header: "Hotfix", Question: "Which commits are the hotfix? (comma-separated SHAs or 'all')", Options: "all", first SHA.

**1.3** If argument is a SHA, use that directly.

**1.4** For each hotfix commit, gather: SHA, message, author, files changed, diff stat.

### Phase 2: Gather Context

AskUserQuestion — Header: "Incident", Question: "Brief description of what broke and why the hotfix was needed".

Collect:
- **Impact**: What was broken? (service down, data loss, degraded performance)
- **Duration**: How long was the issue present?
- **Root cause**: Why did it break?
- **Fix**: What the hotfix commits do

### Phase 3: Create Incident Ticket

Create a Linear ticket via `linear_create_issue()`:
- **title**: `Hotfix: {brief description}`
- **team**: Use team from recent tickets or `.forge` config
- **priority**: 1 (Urgent)
- **description** (markdown):

```markdown
## Incident Summary

**Date:** {today}
**Duration:** {duration from Phase 2}
**Impact:** {impact from Phase 2}

## Root Cause

{root cause from Phase 2}

## Fix Applied

{description of what the commits do}

## Emergency Response

Direct push(es) to `main` bypassing branch protection. Documented here as the audit trail.

Commits:
{for each commit: - `{sha}` — {message}}

## Prevention

{suggest preventive measures based on root cause}

## Related

- Backport PR to staging: (created in Phase 4)
```

Extract `HOTFIX_TICKET_ID` and `HOTFIX_TICKET_URL` from the response.

### Phase 4: Create Backport PR

**4.1** Create branch from staging:
```bash
git checkout -b ${HOTFIX_TICKET_ID}-hotfix-backport origin/staging
```

**4.2** Cherry-pick each hotfix commit:
```bash
git cherry-pick {sha1} {sha2} ... --no-commit
git commit -m "${HOTFIX_TICKET_ID}: backport hotfix — {brief description}"
```

If cherry-pick has conflicts: resolve by taking the hotfix version (`--theirs`), since the hotfix is the source of truth.

**4.3** Push and create PR:
```bash
git push -u origin ${HOTFIX_TICKET_ID}-hotfix-backport
```

```bash
gh pr create \
  --head "${HOTFIX_TICKET_ID}-hotfix-backport" \
  --base staging \
  --title "${HOTFIX_TICKET_ID}: Backport hotfix — {brief description}" \
  --body "## Linear Tickets

| Ticket | Title | Status |
|--------|-------|--------|
| [${HOTFIX_TICKET_ID}](${HOTFIX_TICKET_URL}) | ${TITLE} | In Progress |

---
## Summary

Backport of production hotfix to staging for branch convergence.

{description of changes}

## Context

Production incident required emergency direct push to main. This PR backports that fix through the normal review flow.

## Test plan

- [ ] Staging deploy succeeds
- [ ] No regressions from cherry-pick
"
```

**4.4** Update Linear ticket with PR link:
`linear_update_issue(issueId: HOTFIX_TICKET_ID, state: "In Progress")`

### Phase 5: Report

Output summary:
- Incident ticket: `{HOTFIX_TICKET_ID}` with URL
- Backport PR: `#{pr_number}` with URL
- Commits documented: count and list
- Next steps: review and merge the backport PR

## Error Handling
- No divergent commits found: Report that main and staging are in sync, no hotfix detected
- Cherry-pick conflicts: Attempt auto-resolve with `--theirs`, warn if manual resolution needed
- Linear MCP unavailable: WARN, skip ticket creation, still create backport PR
- Branch already exists: Ask to reuse or create new
