---
description: Build comprehensive PR compliance document (SOC2 audit record)
---
# /verify-pr - Build Comprehensive PR Compliance Document

> **CRITICAL**: MUST run Ticket Traceability Check (Phase 1.6) before building PR body. Do NOT skip — most important SOC2 verification.

**Prerequisites**: Linear MCP configured in `.mcp.json`

```
/verify-pr
/verify-pr --fix    # Auto-fix: build comprehensive PR body
```

### Phase 1: Gather Sources

**1.1** Get PR:
```bash
BRANCH=$(git branch --show-current)
gh pr list --head "$BRANCH" --base staging --json number,url,title,body
```
If no PR: `No PR found. Run /forge:pr first.`

**1.2** Extract tickets from non-merge commits on this branch only: `git log staging..HEAD --no-merges --first-parent --format="%s%n%b"`. Read `.forge` for `LINEAR_PROJECTS`. Build regex patterns dynamically. Extract unique ticket IDs. **IMPORTANT:** `--first-parent` excludes commits inherited from merging origin/staging — only commits authored on this branch are considered.

**1.3** Read `issues/{TICKET_ID}.md` (Summary, Acceptance Criteria, Out of Scope). If missing, `linear_get_issue(id)`.

**1.4** Find spec: `ls specs/*${TICKET_ID}*.md`. Parse Architecture Summary, Key Changes, Decisions.

**1.5** Verify each ticket in Linear: `linear_get_issue(id)`

**1.6: MANDATORY Ticket Traceability Check (BLOCKING)**
```bash
COMMITS_TICKETS=$(git log staging..HEAD --no-merges --first-parent --format="%s%n%b" | grep -oE "[A-Z]+-[0-9]+" | sort -u)
PR_BODY=$(gh pr view --json body -q '.body')
PR_TICKETS=$(echo "$PR_BODY" | grep -oE "[A-Z]+-[0-9]+" | sort -u)
MISSING_FROM_PR=$(comm -23 <(echo "$COMMITS_TICKETS") <(echo "$PR_TICKETS"))
EXTRA_IN_PR=$(comm -13 <(echo "$COMMITS_TICKETS") <(echo "$PR_TICKETS"))
```
Check untracked commits: `git log staging..HEAD --first-parent --oneline | grep -v "[A-Z]\+-[0-9]\+" | grep -v "^[a-f0-9]* Merge"`

**If discrepancies**: AskUserQuestion — Header: "Compliance", Options: "Add missing tickets to PR" (recommended), "From merge commits - note in audit trail", "Create tickets for untracked commits", "Abort". **Do NOT proceed until resolved.**

### Phase 2: Verification Prompts
For each acceptance criterion, AskUserQuestion — Header: "Verify", Question: "How was '{criterion}' verified?", Options: "Test: {auto-suggest file}", "Manual: describe", "Review: code inspection", "N/A: not in scope". Store responses.

### Phase 3: Detect Unspecced Changes
`git diff staging...HEAD --name-only` — check each file against spec, issue, ticket. Unspecced → add to ticket scope (update Linear), create new ticket, or note as infra/config.

### Phase 4: Build Comprehensive PR Body

**4.1 TL;DR** — One sentence: primary ticket + key change.
**4.2 Linear Tickets** — `| Ticket | Title | Status |` with links to Linear.
**4.3 Product Requirements** — From `issues/`: Summary, Acceptance Criteria (`| # | Criterion | Status | Verification |`), Out of Scope. Multiple tickets → subsections per ticket.
**4.4 Technical Implementation** — From `specs/`: Architecture Summary, Key Changes (`| File | Change | Description |` from `git diff staging...HEAD --stat`).
**4.5 Notable Decisions** — From spec's decisions/trade-offs. Omit if none.
**4.6 Testing & Verification** — `| Type | Status | Details |` (Unit/Integration/Manual). Detect tests: `git diff staging...HEAD --name-only | grep -E "test_|_test\.|\.test\."`
**4.7 Audit Trail** — Ticket linkage + scope changes from Phase 3.
**4.8 Assemble** — Use `<details>` for 12+ criteria. PR is single source of truth — completeness over brevity.

### Phase 5: Update PR

**5.1** Title: `gh pr edit <number> --title "<ticket>: <title>"`
**5.2** Body: `gh pr edit <number> --body "$(cat <<'EOF' ... EOF)"`
**5.3** Validate ticket links (curl 404 check)
**5.4** Cross-link: `linear_list_comments(issueId)` → if no PR URL: `linear_create_comment(issueId, body: "PR: <url>")`

### Phase 6: Final Report
Report sections built, criteria verified count, cross-links, pass/fail. Failure blocks `/forge:finish`.

## Edge Cases
- **No issue file**: Fetch from Linear, note "generated from Linear" in Audit Trail
- **No spec file**: Use commits for Technical Implementation, note in Audit Trail
- **Multiple tickets**: Primary → TL;DR; each → Product Requirements subsection; single Technical Implementation
- **Large PRs**: `<details>` for lengthy sections; TL;DR, Tickets, Testing always visible
