---
description: Fetch Linear issue, save requirements, and create technical implementation plan
---
# /load - Load an Issue into Current Session

**Prerequisites**: Linear MCP configured in `.mcp.json`

```
/load <id>
/load 277
/load ENG-277
```

### Phase 1: Setup

1. **Parse Issue ID**: Extract prefix from existing issues or Linear workspace. Numeric only → add prefix. Normalize uppercase.

2. **Check for Existing Work**:
```bash
git branch -a | grep -i "{issue-id}"
gh pr list --search "{ISSUE-ID}" --json number,title,url,headRefName
ls issues/*{number}* specs/*{number}* 2>/dev/null
```
If found: report what exists, ask user to continue or start fresh.

### Phase 2: Process Issue (Recursive)

Call `ProcessIssue({ISSUE-ID}, isRoot=true)`:

1. Fetch: `linear_get_issue(id: issueId)` → title, description, state, assignee, project, labels
2. Check children: `linear_list_issues(parentId: issueId)` — NOTE: get_issue does NOT return children
3. **If has children**: list all, recurse each child, create parent summary files (see below), return
4. **Draft issues/{ISSUE-ID}.md** (product-focused, NO code/architecture):
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
7. **Draft specs/{issue-id-lowercase}.md**:
   ```markdown
   # {ISSUE-ID}: {Title} - Technical Spec
   > See [{ISSUE-ID}](../issues/{ISSUE-ID}.md) for product requirements.
   ## Architecture Overview
   ## Implementation Plan
   ### 1. {Task} — Files: `path`, Changes: {what}
   ## Data Models / API Contracts
   ## Edge Cases & Error Handling
   ## Testing Strategy
   ## Open Questions
   ```
8. **Show spec to user**, ask: "approve / modify"
9. **Sync to Linear** (non-root only): `linear_update_issue(issueId, description: "{issues content}")`
10. Report: `{ISSUE-ID}: {Title} — approved{, Linear updated if not root}`

#### Parent Summary Files (for issues with children)

After all children processed:
- `issues/{PARENT-ID}.md`: Summary, Child Issues links, `- [ ] All child issues completed`
- `specs/{parent-id}.md`: Architecture Overview (how children fit together), Child Specs links, Implementation Order (sequence + dependencies), Integration Points

### Phase 3: Final Summary

Report: feature description, all files created, numbered implementation steps, complexity estimate (Low/Medium/High). Ask: proceed, modify, or discuss?

## Error Handling
- **Linear MCP not available**: ask user to configure `.mcp.json`
- **Issue not found**: suggest checking ID
- **Existing work conflicts**: present options to user
