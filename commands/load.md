---
description: Fetch Linear issue, save requirements, and create technical implementation plan
---
# /load - Load an Issue into Current Session

**Prerequisites**: Linear MCP configured in `.mcp.json`

```
/load <id>
/load 277
/load PROJ-277
```

### Arguments

`/forge:load <issue-id> [--unattended]`. **`--unattended` is a mode flag, not part of the issue ID** — strip it before parsing the ID. The issue ID is the non-flag token (or inferred from the branch if omitted).

### Unattended Mode (`--unattended`)

When invoked with `--unattended` (the dispatched background agent always is), run the
**entire flow without stopping to ask the user anything**:
- **Do NOT call `AskUserQuestion`, and treat every prose "ask the user…" step below as auto-resolved** — including "approve / modify / skip", "proceed / modify / discuss". Sensible defaults: existing work → continue it; issue/spec draft → approve; ambiguous scope → pick the most reasonable interpretation.
- Make best-judgment decisions and **record any non-obvious assumption** in an `## Assumptions` section at the top of the spec when posting it to Linear so it's auditable.
- After the spec is approved-by-default, **implement the change**, then run `/forge:verify {ID} --unattended` as the end-of-implementation step.
- Only stop for a **truly blocking external need** the agent cannot resolve itself: missing auth/credentials, missing access, or a Linear/MCP outage. Log it clearly and halt; never block on a stylistic or scoping question.

Interactive mode (no `--unattended`) keeps all the approval gates described below.


### Phase 1: Setup

1. **Parse Issue ID**: Extract prefix from existing issues or Linear workspace. Numeric only → add prefix. Normalize uppercase.

2. **Check for Existing Work**:
```bash
git branch -a | grep -i "{issue-id}"
gh pr list --search "{ISSUE-ID}" --json number,title,url,headRefName
```
If found: report what exists, ask user to continue or start fresh.

### Phase 2: Process Issue (Recursive)

Call `ProcessIssue({ISSUE-ID}, isRoot=true)`:

1. Fetch: `linear_get_issue(id: issueId)` → title, description, state, assignee, project, labels
2. Check children: `linear_list_issues(parentId: issueId)` — NOTE: get_issue does NOT return children
3. **If has children**: list all, recurse each child, post parent summary comment to Linear (see below), return
4. **Draft product summary** (in-session, no file):
   ```markdown
   # {ISSUE-ID}: {Title}
   ## Summary
   {2-3 sentence business description}
   ## User Stories
   - As a {role}, I want {feature} so that {benefit}
   ## Acceptance Criteria
   - [ ] {Criterion}
   ## Business Rules
   - {Rule}
   ## Out of Scope
   - {Exclusions}
   ```
5. **Show to user**, ask: "approve / modify / skip". If skip → return (no spec).
6. **Research codebase**: analyze affected code, identify patterns, check conflicts/dependencies
7. **Draft spec** (in-session, no file):
   ```markdown
   # {ISSUE-ID}: {Title} - Technical Spec
   ## Architecture Overview
   ## Implementation Plan
   ### 1. {Task} — Files: `path`, Changes: {what}
   ## Data Models / API Contracts
   ## Edge Cases & Error Handling
   ## Testing Strategy
   ## Open Questions
   ```
8. **Show spec to user**, ask: "approve / modify"
9. **Post to Linear**: `linear_save_comment(issueId, body: "## Technical Spec\n\n{spec content}")` — posts the spec as a comment on the ticket
10. Report: `{ISSUE-ID}: {Title} — approved, spec posted to Linear`

#### Parent Summary Comment (for issues with children)

After all children processed, post a comment on the parent Linear ticket:
- Summary of the parent feature
- Links to all child issues
- Architecture overview of how children fit together
- Implementation order (sequence + dependencies)
- Integration points

### Phase 3: Final Summary

Report: feature description, spec posted to Linear, numbered implementation steps, complexity estimate (Low/Medium/High). Ask: proceed, modify, or discuss?

**After implementation completes** (code written for a web ticket), run `/forge:verify {ISSUE-ID}` as the end-of-implementation step: it drives the running app in a real browser against the acceptance criteria, auto-fixes breakage (capped retries), and posts the verified user story + screenshots to Linear. Don't mark work ready until verification passes.

## Error Handling
- **Linear MCP not available**: ask user to configure `.mcp.json`
- **Issue not found**: suggest checking ID
- **Existing work conflicts**: present options to user
