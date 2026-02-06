---
description: Promote staging to production with full compliance audit trail
---

# /release - Production Release with SOC2 Compliance

You are a Release Manager responsible for promoting tested code from staging to production with full SOC2 audit trail.

**Prerequisites**:
- Linear MCP server must be configured in `.mcp.json`
- Must be on the `staging` branch or `main` branch
- `gh` CLI authenticated

## Usage

```
/release
/release --dry-run    # Show what would be released without executing
```

## Why This Matters (SOC2)

Direct merges from staging to main bypass compliance controls. This command ensures:

1. **Authorization**: Explicit human confirmation before production deploy
2. **Audit trail**: Permanent record of what was released, when, and by whom
3. **Traceability**: Links release to all PRs and Linear tickets included
4. **Evidence**: Proof that staging was validated before promotion

## CRITICAL: Confirmation Word System

To prevent accidental releases, generate a **random confirmation word** for each release. The user must type this exact word to proceed.

**Word Selection Rules:**
- Pick a random word from this list for EACH release (never the same word twice in a row):
  ```
  DEPLOY, RELEASE, SHIP, LAUNCH, PROMOTE, CONFIRM, PROCEED, EXECUTE,
  AUTHORIZE, APPROVE, PUBLISH, DELIVER, ACTIVATE, ENABLE, GO
  ```
- Display the word prominently in the confirmation prompt
- User must type it EXACTLY (case-sensitive)
- This ensures the user is paying attention, not just hitting enter

## Workflow

### Phase 1: Pre-flight Checks

#### 1.1: Verify Current State

```bash
# Must be on staging or main
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "staging" && "$CURRENT_BRANCH" != "main" ]]; then
  echo "Must be on staging or main branch to release"
  exit 1
fi

# Fetch latest
git fetch origin staging main
```

#### 1.2: Check Staging is Ahead of Main

```bash
# Count commits staging has that main doesn't
COMMITS_AHEAD=$(git rev-list --count origin/main..origin/staging)
if [[ "$COMMITS_AHEAD" -eq 0 ]]; then
  echo "Nothing to release: staging and main are identical"
  exit 0
fi
```

#### 1.3: Verify CI Status on Staging

```bash
# Get latest staging commit
STAGING_SHA=$(git rev-parse origin/staging)

# Check CI status
gh api repos/{owner}/{repo}/commits/$STAGING_SHA/status --jq '.state'
# Must be "success"

# Also check required checks
gh api repos/{owner}/{repo}/commits/$STAGING_SHA/check-runs --jq '.check_runs[] | "\(.name): \(.conclusion)"'
```

If CI is not passing, STOP:
```
CI checks have not passed on staging.

Status: {state}
Failed checks:
- {check_name}: {conclusion}

Fix staging before releasing to production.
```

#### 1.4: Check for Open PRs Targeting Staging

```bash
gh pr list --base staging --state open --json number,title,author
```

If open PRs exist, WARN:
```
WARNING: {N} open PRs targeting staging

| PR | Title | Author |
|----|-------|--------|
| #123 | Feature X | @user |

These changes are NOT included in this release.
Consider merging or closing them first.
```

### Phase 2: Gather Release Contents

#### 2.1: Get Commits in Release

```bash
# All commits from main to staging (what will be released)
git log origin/main..origin/staging --oneline --no-merges
```

#### 2.2: Get PRs Included

Extract PR numbers from merge commits:
```bash
git log origin/main..origin/staging --merges --format="%s" | grep -oE "#[0-9]+" | sort -u
```

For each PR, fetch details:
```bash
gh pr view {number} --json number,title,author,mergedAt,url,body
```

#### 2.3: Get Linear Tickets

Extract ticket IDs from commit messages and PR bodies:
```bash
git log origin/main..origin/staging --format="%s%n%b" | grep -oE "BOL-[0-9]+" | sort -u
```

For each ticket, fetch from Linear:
```
linear_get_issue(id: "<ticket-id>")
```

#### 2.4: Get Compliance Archives

For each PR included, check if compliance archive exists:
```bash
git ls-tree -r --name-only origin/compliance-archives compliance/ | grep "pr-{number}"
```

Build list of compliance archive references.

#### 2.5: Calculate Change Summary

```bash
# Files changed
git diff origin/main..origin/staging --stat

# Insertions/deletions
git diff origin/main..origin/staging --shortstat
```

### Phase 3: Build Release Summary

Present a comprehensive summary to the user:

```
================================================================================
                         PRODUCTION RELEASE SUMMARY
================================================================================

From: staging (abc1234)
To:   main (def5678)

--------------------------------------------------------------------------------
WHAT'S BEING DEPLOYED
--------------------------------------------------------------------------------

Commits: {N} commits
PRs:     {N} pull requests
Tickets: {N} Linear tickets
Files:   {N} files changed (+{insertions}/-{deletions})

--------------------------------------------------------------------------------
PULL REQUESTS INCLUDED
--------------------------------------------------------------------------------

| PR | Title | Author | Merged | Compliance |
|----|-------|--------|--------|------------|
| #108 | BOL-407: Session auth... | @dorkalev | 2026-02-04 | Archived |
| #106 | BOL-396: Simplify velocity... | @dorkalev | 2026-02-03 | Archived |
| #111 | fix: push compliance... | @dorkalev | 2026-02-03 | Archived |

--------------------------------------------------------------------------------
LINEAR TICKETS INCLUDED
--------------------------------------------------------------------------------

| Ticket | Title | Status |
|--------|-------|--------|
| [BOL-407](url) | Session auth for browser API | Done |
| [BOL-396](url) | Simplify velocity RMS | Done |
| [BOL-411](url) | Fix LLM analyst inspection | Done |

--------------------------------------------------------------------------------
KEY CHANGES BY AREA
--------------------------------------------------------------------------------

**Web Dashboard:**
- Session authentication for browser API endpoints
- Custom 404 and 500 error pages
- LLM analysis section fixes

**Algorithm Service:**
- Simplified velocity RMS calculations
- Zero-padding for clean FFT bins

**Infrastructure:**
- Compliance archives on dedicated branch
- Database admin documentation

--------------------------------------------------------------------------------
COMPLIANCE STATUS
--------------------------------------------------------------------------------

[x] CI passing on staging
[x] All PRs have compliance archives
[x] All tickets linked and verified
[x] No unspecced changes detected

--------------------------------------------------------------------------------
```

### Phase 4: User Confirmation

Generate a random confirmation word and present the final warning:

```
================================================================================
                              CONFIRM RELEASE
================================================================================

You are about to deploy {N} commits to PRODUCTION.

This will:
1. Fast-forward main to staging
2. Trigger production deployment to boltx-core
3. Create permanent release record in compliance-archives

WARNING: This action deploys to PRODUCTION and affects live users.

To confirm, type the word: {RANDOM_WORD}

>
```

Use AskUserQuestion with:
- Header: "Release"
- Question: "Type '{RANDOM_WORD}' to confirm production release, or 'ABORT' to cancel"
- Options:
  - "{RANDOM_WORD}" - "Confirm and deploy to production"
  - "ABORT" - "Cancel release"

**If user selects ABORT or anything other than the exact word, stop immediately.**

### Phase 5: Execute Release

#### 5.1: Create Release Record

Build comprehensive release JSON:

```json
{
  "release_id": "release-{YYYY-MM-DD}-{sequence}",
  "timestamp": "{ISO8601}",
  "released_by": "{git user.name}",
  "released_by_email": "{git user.email}",

  "from_ref": "main",
  "from_sha": "{main SHA before}",
  "to_ref": "staging",
  "to_sha": "{staging SHA}",

  "commits_count": {N},
  "files_changed": {N},
  "insertions": {N},
  "deletions": {N},

  "pull_requests": [
    {
      "number": 108,
      "title": "BOL-407: Session auth...",
      "url": "https://github.com/...",
      "author": "dorkalev",
      "merged_at": "2026-02-04T09:57:20Z",
      "compliance_archive": "compliance/pr-108-BOL-407-session-auth-...-20260204.json"
    }
  ],

  "linear_tickets": [
    {
      "id": "BOL-407",
      "title": "Session auth for browser API endpoints",
      "url": "https://linear.app/boltx/issue/BOL-407",
      "status": "Done"
    }
  ],

  "change_summary": {
    "web": ["Session auth", "Custom error pages"],
    "algo": ["Simplified velocity RMS", "Zero-padding FFT"],
    "infra": ["Compliance archives", "DB admin docs"]
  },

  "ci_status": {
    "staging_sha": "{sha}",
    "status": "success",
    "checks_passed": ["algo-test", "web-test", "soc2-compliance"]
  },

  "confirmation": {
    "word_presented": "{RANDOM_WORD}",
    "word_entered": "{what user typed}",
    "confirmed_at": "{ISO8601}"
  }
}
```

#### 5.2: Push Release Record to compliance-archives

```bash
# Checkout compliance-archives branch
git worktree add /tmp/compliance-archives origin/compliance-archives 2>/dev/null || true
cd /tmp/compliance-archives
git pull origin compliance-archives

# Create releases directory if needed
mkdir -p releases

# Write release JSON file
RELEASE_BASENAME="release-$(date +%Y-%m-%d)-$(date +%H%M%S)"
RELEASE_JSON="releases/${RELEASE_BASENAME}.json"
RELEASE_MD="releases/${RELEASE_BASENAME}.md"

cat > "$RELEASE_JSON" << 'EOF'
{release JSON}
EOF

# Commit and push
git add "$RELEASE_JSON" "$RELEASE_MD"
git commit -m "release: $(date +%Y-%m-%d) - {N} PRs, {N} tickets"
git push origin compliance-archives

# Cleanup worktree
cd -
git worktree remove /tmp/compliance-archives
```

#### 5.2.1: Generate Release Markdown Report

Create a human-readable Markdown report alongside the JSON:

```markdown
# Release: {YYYY-MM-DD}

> Released by: {git user.name}
> Released at: {ISO8601 timestamp}

## Summary

| Metric | Value |
|--------|-------|
| **Commits** | {N} |
| **Pull Requests** | {N} |
| **Linear Tickets** | {N} |
| **Files Changed** | {N} (+{insertions}/-{deletions}) |

## From → To

- **From**: `main` @ `{short SHA before}`
- **To**: `staging` @ `{short SHA}`

## Pull Requests Included

| PR | Title | Author | Merged | Compliance Archive |
|----|-------|--------|--------|-------------------|
| [#108]({url}) | BOL-407: Session auth... | @dorkalev | 2026-02-04 | [📋 Report]({archive_url}) |
| [#106]({url}) | BOL-396: Simplify velocity... | @dorkalev | 2026-02-03 | [📋 Report]({archive_url}) |

## Linear Tickets

| Ticket | Title | Status |
|--------|-------|--------|
| [BOL-407]({linear_url}) | Session auth for browser API | Done |
| [BOL-396]({linear_url}) | Simplify velocity RMS | Done |

## Changes by Area

### Web Dashboard
- Session authentication for browser API endpoints
- Custom 404 and 500 error pages

### Algorithm Service
- Simplified velocity RMS calculations
- Zero-padding for clean FFT bins

### Infrastructure
- Compliance archives on dedicated branch

## CI Status

All checks passed on staging before release.

| Check | Status |
|-------|--------|
| algo-test | ✅ passed |
| web-test | ✅ passed |
| soc2-compliance | ✅ passed |

## Confirmation

- **Word presented**: {RANDOM_WORD}
- **Confirmed at**: {ISO8601}
```

Write this to `$RELEASE_MD` before committing.

#### 5.3: Fast-Forward Main to Staging

```bash
git checkout main
git merge --ff-only origin/staging
git push origin main
```

If fast-forward fails (main has diverged):
```
ERROR: Cannot fast-forward main to staging.

Main has commits not in staging. This should not happen in normal workflow.

Options:
1. Investigate: git log origin/staging..origin/main
2. Merge staging into main (creates merge commit)
3. Abort and investigate manually

This usually indicates someone pushed directly to main.
```

#### 5.4: Verify Deployment Triggered

```bash
# Check GitHub Actions
gh run list --branch main --limit 1 --json status,conclusion,name,url
```

Report deployment status:
```
Deployment triggered.

GitHub Actions: {run_url}
Status: {in_progress/queued}

Monitor at: https://console.cloud.google.com/run?project=boltx-core
```

### Phase 6: Post-Release

#### 6.1: Update Linear Tickets

For each ticket in the release, add a comment:
```
linear_create_comment(
  issueId: "<id>",
  body: "Released to production in release-{id}\n\nRelease: {archive_url}\nDeploy: {github_actions_url}"
)
```

#### 6.2: Final Report

```
================================================================================
                           RELEASE COMPLETE
================================================================================

Release ID: release-2026-02-04-153045

Production deployment triggered:
  - {N} commits
  - {N} pull requests
  - {N} Linear tickets

Compliance Archive:
  Branch: compliance-archives
  File:   releases/release-2026-02-04-153045.json

Deployment:
  GitHub Actions: {url}
  Cloud Run:      https://console.cloud.google.com/run?project=boltx-core

Linear tickets updated with release comment.

--------------------------------------------------------------------------------
Monitor deployment progress in Slack or Cloud Console.
================================================================================
```

## Dry Run Mode

When `--dry-run` is specified:
- Execute Phases 1-3 (checks and summary)
- Skip Phases 4-6 (confirmation and execution)
- Report what WOULD happen without making changes

```
DRY RUN MODE - No changes will be made

{Full release summary}

To execute this release, run: /release
```

## Error Handling

### CI Not Passing
```
BLOCKED: CI checks have not passed on staging.

Failed checks:
- {check}: {status}

Fix staging before releasing.
```

### No Changes to Release
```
Nothing to release.

staging and main are at the same commit: {sha}
```

### Main Has Diverged
```
ERROR: main has diverged from staging.

main has {N} commits not in staging.
This indicates direct pushes to main, which violates the workflow.

Investigate with: git log origin/staging..origin/main

Do NOT force-push. Resolve the divergence manually.
```

### Compliance Archive Missing
```
WARNING: PR #{number} has no compliance archive.

This PR may have been merged before compliance archiving was enabled,
or the archive workflow failed.

The release will note this gap in the audit trail.
```

### Linear Ticket Not Found
```
WARNING: Ticket {ID} not found in Linear.

This may be a typo in commit messages or a deleted ticket.
The release will proceed but note this in the audit trail.
```

## Output Files

### Release Archive Format

Location: `compliance-archives/releases/release-{YYYY-MM-DD}-{HHMMSS}.json`

Contains:
- Full release metadata
- All PRs with compliance archive references
- All Linear tickets with status
- Change summary by area
- CI verification
- User confirmation record

This file serves as the **permanent SOC2 audit record** for production deployments.
