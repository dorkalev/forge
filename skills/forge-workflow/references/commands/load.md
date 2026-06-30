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
