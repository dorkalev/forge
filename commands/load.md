---
description: Fetch a Linear issue, research the codebase, and implement the change
---
# /load - Load and Implement a Linear Issue

**Prerequisites**: Linear MCP configured in `.mcp.json`

```
/load <id>                   # interactive: shows plan, asks for approval
/load ENG-277 --unattended   # unattended mode: fully autonomous, no approval gates
```

### Arguments

`/forge:load <issue-id> [--unattended]`. `--unattended` is a mode flag, not part of the ID — strip it before parsing. The issue ID is the non-flag token (or inferred from the branch if omitted).

---

## Unattended Mode (`--unattended`)

Use this mode only when explicitly requested (automation, no human in the loop).

Run the **entire flow without stopping**:
- **No `AskUserQuestion` calls.** All approval gates are auto-resolved.
- Sensible defaults: existing work → continue it; ambiguous scope → pick the most reasonable interpretation.
- Record any non-obvious assumptions in an `## Assumptions` section of the spec comment posted to Linear.
- **Only stop for a truly blocking external need**: missing credentials, repo access failure, or Linear/MCP outage. Never stop on stylistic or scoping questions.

---

## Phase 1: Setup

**Parse issue ID**: if numeric only, add the project prefix (check existing `issues/` filenames or Linear workspace). Normalize uppercase.

**Check for existing work** (run in parallel):
```bash
git branch -a | grep -i "{issue-id}"
gh pr list --search "{ISSUE-ID}" --json number,title,url,headRefName
```
Interactive: if found, report and ask to continue or start fresh.
Unattended: if found, continue the existing work.

## Phase 2: Process Issue

1. `linear_get_issue(id)` → title, description, state
2. `linear_list_issues(parentId: id)` → check for child issues
3. **If has children**: recurse each child, post a parent summary comment to Linear, return.

**Draft product summary** (in-session, no file):
```
# {ID}: {Title}
## Summary
## User Stories
## Acceptance Criteria
## Out of Scope
```

Interactive: show, ask "approve / modify / skip".
Unattended: auto-approve.

**Research codebase**: 2-5 targeted searches to identify affected files and patterns.

**Draft technical spec** (in-session, no file):
```
# {ID}: {Title} — Technical Spec
## Implementation Plan
### 1. {Task} — Files: `path`, Changes: {what}
## Edge Cases & Error Handling
## Assumptions (unattended mode only)
```

Interactive: show spec, ask "approve / modify".
Unattended: auto-approve.

**Post spec to Linear**: `linear_save_comment(issueId, body: "## Technical Spec\n\n{spec}")`

## Phase 3: Implement

Execute the implementation plan. For each task:
- Read the target file(s) before editing
- Apply changes with Edit/Write
- Stay strictly within the spec scope

Run linting / type checks after implementation if applicable.

## Phase 4: Verify (browser evidence)

Run `/forge:verify {ID} --unattended`:
- Starts the dev server, drives the app in a real browser via Playwright
- Proves each acceptance criterion; collects screenshots + console + network evidence
- Auto-fixes breakage (max 3 cycles)
- On success: posts verified user story + screenshots to Linear
- Non-browser criteria (pure backend) are noted as skipped — never fabricated
- If Playwright MCP is unavailable: skip silently and note it in the report

This is the proof that the implementation actually works, not just that it compiles.

## Phase 5: Report

State: issue ID, files changed, what was done, verification result (pass / skip / fail with reason), any deferred items.

Interactive: ask "proceed to `/forge:finish`, or discuss?"

---

## Error Handling
- **Linear MCP unavailable**: stop and ask user to configure `.mcp.json`
- **Issue not found**: suggest checking the ID
