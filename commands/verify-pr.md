---
description: Build comprehensive PR compliance document (SOC2 audit record)
---

# /verify-pr - Build Comprehensive PR Compliance Document

You are an elite DevOps Compliance Engineer ensuring the PR is a **self-contained SOC2 audit record**.

> **⚠️ CRITICAL**: Before building the PR body, you MUST run the Ticket Traceability Check (Phase 1.6).
> This compares tickets in commits vs PR description. Do NOT skip this step - it's the most important
> SOC2 verification. Building a "nice looking" PR without this check defeats the purpose of compliance.

**Prerequisites**: Linear MCP server must be configured in `.mcp.json`

## Usage

```
/verify-pr
/verify-pr --fix    # Auto-fix: build comprehensive PR body
```

## Why This Matters (SOC2)

The PR is the **definitive compliance audit trail**. An auditor should be able to look at ANY merged PR and immediately understand:

1. What was the product requirement? (Product Requirements section)
2. How was it implemented? (Technical Implementation section)
3. How was it verified? (Acceptance Criteria table with verification)
4. Which tickets authorized it? (Linear Tickets table with validated links)

**Without leaving the GitHub PR page.**

## Target PR Structure

```markdown
# ENG-123: Feature Title

## TL;DR
One-sentence summary of what this PR accomplishes.

---

## Linear Tickets
| Ticket | Title | Status |
|--------|-------|--------|
| [ENG-123](url) | Main Feature | Done |
| [ENG-124](url) | Related Fix | Done |

---

## Product Requirements

### Summary
{From issues/{TICKET}.md - the business problem being solved}

### Acceptance Criteria
| # | Criterion | Status | Verification |
|---|-----------|--------|--------------|
| 1 | User can do X | [x] Done | Test: test_feature.py |
| 2 | System handles Y | [x] Done | Manual: verified logs |
| 3 | Performance meets Z | [x] Done | Review: code inspection |

### Out of Scope
- {Items explicitly excluded}

---

## Technical Implementation

### Architecture Summary
{Condensed from specs/{feature}.md - key technical approach}

### Key Changes
| File | Change | Description |
|------|--------|-------------|
| src/module.py | Modified | Added feature X handler |
| tests/test_module.py | Added | Unit tests for feature X |

### Notable Decisions
- **Decision**: {What was decided}
- **Rationale**: {Why}

---

## Testing & Verification
| Type | Status | Details |
|------|--------|---------|
| Unit | Passed | 12 tests |
| Integration | Passed | Pipeline e2e |
| Manual | Passed | Verified in staging |

---

## Audit Trail
- All tickets linked with comments
- Scope changes: {None | Listed}

---
*Verified by Forge compliance workflow*
```

## Workflow

### Phase 1: Gather Sources

#### 1.1: Get PR Information

```bash
BRANCH=$(git branch --show-current)
gh pr list --head "$BRANCH" --base staging --json number,url,title,body
```

If no PR exists:
```
No PR found for branch: $BRANCH
Run /forge:pr to create one first.
```

#### 1.2: Extract Tickets from Commits

Scan ALL commit messages since staging (excluding merge commits to avoid picking up tickets already in staging):

```bash
git log staging..HEAD --no-merges --format="%s%n%b"
```

Read `.forge` file to get `LINEAR_PROJECTS` (e.g., `VLAD,ENGINEERING,INFRA,ALGO,XD`).

Build regex patterns dynamically:
- `ENG-\d+` for ENGINEERING (example prefix)
- `TEAM-\d+`, `INFRA-\d+`, `PROJ-\d+`, `XD-\d+`

Extract all unique ticket IDs found in commits.

#### 1.3: Read Issue Files

For each ticket ID, read the corresponding issue file:

```
issues/{TICKET_ID}.md
```

Parse the issue file for:
- **Summary**: The "## Summary" or "## Description" section
- **Acceptance Criteria**: The "## Acceptance Criteria" section (list of `- [ ]` or `- [x]` items)
- **Out of Scope**: The "## Out of Scope" section

If issue file doesn't exist, fetch from Linear:
```
linear_get_issue(id: "<ticket-id>")
```

#### 1.4: Read Spec File

Derive feature name from branch (e.g., `eng-123-fix-login` -> look for `specs/fix-login.md` or `specs/eng-123-fix-login.md`).

```bash
# Try exact match first
ls specs/*${TICKET_ID}*.md 2>/dev/null || ls specs/*.md | head -5
```

Parse the spec file for:
- **Architecture Summary**: First paragraph or "## Overview" section
- **Key Changes**: "## Changes" or "## Implementation" section
- **Notable Decisions**: "## Decisions" or "## Trade-offs" section

#### 1.5: Fetch Linear Status

For each ticket, verify it exists and get current status:
```
linear_get_issue(id: "<ticket-id>")
```

#### 1.6: MANDATORY Ticket Traceability Check (BLOCKING)

**This step is CRITICAL and must not be skipped.**

Compare tickets found in commits against tickets in current PR body:

```bash
# Get tickets from commits (exclude merge commits to avoid staging tickets)
COMMITS_TICKETS=$(git log staging..HEAD --no-merges --format="%s%n%b" | grep -oE "[A-Z]+-[0-9]+" | sort -u)

# Get tickets from current PR body
PR_BODY=$(gh pr view --json body -q '.body')
PR_TICKETS=$(echo "$PR_BODY" | grep -oE "[A-Z]+-[0-9]+" | sort -u)

# Find discrepancies
MISSING_FROM_PR=$(comm -23 <(echo "$COMMITS_TICKETS") <(echo "$PR_TICKETS"))
EXTRA_IN_PR=$(comm -13 <(echo "$COMMITS_TICKETS") <(echo "$PR_TICKETS"))
```

Also check for commits WITHOUT ticket IDs:
```bash
git log staging..HEAD --oneline | grep -v "[A-Z]\+-[0-9]\+" | grep -v "^[a-f0-9]* Merge"
```

**Output a compliance report before proceeding:**

```
╔══════════════════════════════════════════════════════════════╗
║                 TICKET TRACEABILITY CHECK                     ║
╠══════════════════════════════════════════════════════════════╣
║ Tickets in commits:  ENG-123, ENG-124, ENG-125, XD-42        ║
║ Tickets in PR body:  ENG-123, ENG-125                        ║
╠══════════════════════════════════════════════════════════════╣
║ ❌ MISSING FROM PR:  ENG-124, XD-42                          ║
║ ⚠️  UNTRACKED COMMITS: 3 commits without ticket IDs          ║
╚══════════════════════════════════════════════════════════════╝
```

**If discrepancies exist, STOP and ask user:**

Use AskUserQuestion tool:
- Header: "Compliance"
- Question: "Found {N} tickets in commits not in PR, and {M} untracked commits. How to proceed?"
- Options:
  - "Add missing tickets to PR" (recommended)
  - "These are from merge commits - note in audit trail"
  - "Create tickets for untracked commits"
  - "Abort - I'll fix manually"

**Do NOT proceed to Phase 4 (Build PR Body) until all tickets are accounted for.**

This prevents the common mistake of building a "nice looking" PR that doesn't actually trace to all code changes.

### Phase 2: Verification Prompts

For each acceptance criterion from the issue file, prompt the user to confirm verification:

```
Acceptance Criterion: "User can log in with email"
How was this verified?

1. Test file (specify which test)
2. Manual verification (describe what you checked)
3. Code review (inspection only)
4. N/A (not applicable to this PR)
```

Use AskUserQuestion tool with options:
- Header: "Verify"
- Question: "How was '{criterion}' verified?"
- Options:
  - "Test: {auto-suggest test file if found}"
  - "Manual: describe"
  - "Review: code inspection"
  - "N/A: not in scope"

Store each verification response for the acceptance criteria table.

### Phase 3: Detect Unspecced Changes

Compare the diff against what's documented:

```bash
git diff staging...HEAD --name-only
```

For each changed file, check if it's mentioned in:
1. The spec file
2. The issue file's acceptance criteria
3. A related ticket

If a file change doesn't map to any documentation:

```
UNSPECCED CHANGE DETECTED:
File: src/new_feature.py
Not found in: specs/, issues/, or ticket descriptions

Options:
1. Add to current ticket scope - Update Linear issue
2. Create new ticket - Separate for traceability
3. Expected (infra/config) - Note in PR description
```

### Phase 4: Build Comprehensive PR Body

#### 4.1: Build TL;DR

Generate a one-sentence summary combining:
- Primary ticket title
- Key change description

Example: "Fixed vibration processor Docker entrypoint to run job_entrypoint.py instead of analyst_agent."

#### 4.2: Build Linear Tickets Table

```markdown
## Linear Tickets
| Ticket | Title | Status |
|--------|-------|--------|
| [TEAM-123](https://linear.app/team/issue/TEAM-123) | Main Feature | Done |
```

For each ticket, include:
- Link to Linear
- Title from Linear
- Status from verification (Done, In Progress, etc.)

#### 4.3: Build Product Requirements Section

Pull directly from `issues/{TICKET}.md`:

```markdown
## Product Requirements

### Summary
{issues/ Summary section}

### Acceptance Criteria
| # | Criterion | Status | Verification |
|---|-----------|--------|--------------|
| 1 | {criterion text} | [x] Done | {verification from Phase 2} |
| 2 | {criterion text} | [x] Done | {verification from Phase 2} |

### Out of Scope
{issues/ Out of Scope section}
```

**For multiple tickets**: Create subsections:
```markdown
## Product Requirements

### ENG-123: Main Feature

#### Summary
...

#### Acceptance Criteria
...

### ENG-124: Related Fix

#### Summary
...
```

#### 4.4: Build Technical Implementation Section

Condense from `specs/{feature}.md`:

```markdown
## Technical Implementation

### Architecture Summary
{First 2-3 sentences from spec overview}

### Key Changes
| File | Change | Description |
|------|--------|-------------|
```

Generate Key Changes table from git diff:
```bash
git diff staging...HEAD --stat
```

Map each file to a brief description from the spec or commit messages.

#### 4.5: Build Notable Decisions

If spec has a "Decisions" or "Trade-offs" section, include key items:

```markdown
### Notable Decisions
- **Decision**: Use CMD override vs separate Dockerfile
- **Rationale**: Simpler, single Dockerfile for both modes
```

If no decisions documented, omit this section.

#### 4.6: Build Testing & Verification Table

```markdown
## Testing & Verification
| Type | Status | Details |
|------|--------|---------|
| Unit | {Passed/Failed/N/A} | {count} tests |
| Integration | {Passed/Failed/N/A} | {description} |
| Manual | {Passed/Skipped} | {what was verified} |
```

Detect test status:
```bash
# Find test files in diff
git diff staging...HEAD --name-only | grep -E "test_|_test\.|\.test\."
```

#### 4.7: Build Audit Trail

```markdown
## Audit Trail
- All tickets linked with PR comments
- Scope changes: {None | list any scope expansions noted in Phase 3}
```

#### 4.8: Assemble Full PR Body

Combine all sections. For readability, consider using collapsible `<details>` for lengthy sections:

```markdown
<details>
<summary>Full Acceptance Criteria (12 items)</summary>

| # | Criterion | Status | Verification |
...

</details>
```

The PR is the single source of truth - include all necessary information regardless of length.

### Phase 5: Update PR

#### 5.1: Update PR Title

If PR title doesn't include ticket ID:
```bash
gh pr edit <pr-number> --title "<primary-ticket>: <title>"
```

#### 5.2: Update PR Body

```bash
gh pr edit <pr-number> --body "$(cat <<'EOF'
<assembled-pr-body>
EOF
)"
```

#### 5.3: Validate Ticket Links (404 Check)

For each ticket link in the PR:
```bash
curl -s -o /dev/null -w "%{http_code}" "https://linear.app/team/issue/TEAM-123"
```

Report any broken links.

#### 5.4: Add Cross-Links to Linear

For each ticket, check if PR is already linked:
```
linear_list_comments(issueId: "<id>")
```

If no comment contains the PR URL:
```
linear_create_comment(issueId: "<id>", body: "PR: <pr-url>")
```

### Phase 6: Final Report

```
PR Compliance Document Built

   PR: #123 - ENG-123: Implement feature X
   URL: https://github.com/org/repo/pull/123

   Sections:
   [x] TL;DR
   [x] Linear Tickets (3)
   [x] Product Requirements
   [x] Acceptance Criteria (5/5 verified)
   [x] Technical Implementation
   [x] Testing & Verification
   [x] Audit Trail

   Cross-links: 3/3 tickets have PR comments

   Ready for review
```

Or if issues remain:

```
PR Compliance Failed

   Missing verifications:
   - Criterion #3: "Performance meets SLA" - not verified

   Unspecced changes:
   - src/utils/helper.py - not documented

   Run /verify-pr --fix to resolve
```

## Handling Edge Cases

### No Issue File Exists

If `issues/{TICKET}.md` doesn't exist:
1. Fetch from Linear: `linear_get_issue(id: "<ticket-id>")`
2. Use Linear description as Summary
3. Note in Audit Trail: "Issue file generated from Linear"

### No Spec File Exists

If no spec file found:
1. Use commit messages for Technical Implementation
2. Generate Key Changes from diff only
3. Note in Audit Trail: "No spec file - implementation details from commits"

### Multiple Tickets

When PR covers multiple tickets:
1. Primary ticket (first in commits) provides TL;DR
2. Each ticket gets its own subsection in Product Requirements
3. Combine all acceptance criteria into single verification table
4. Single Technical Implementation section covers all

### Large PRs

For readability, consider collapsible sections for lengthy content:
```markdown
<details>
<summary>Product Requirements (click to expand)</summary>
...
</details>
```

Keep TL;DR, Linear Tickets, and Testing tables always visible. The PR is the single source of truth - completeness is more important than brevity.

## Exit Codes

- **Pass**: All sections present, all criteria verified, cross-links exist
- **Fail**: Missing verifications, unspecced changes, or broken links

When invoked from `/forge:finish`, a failure blocks the workflow.
