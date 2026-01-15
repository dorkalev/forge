---
description: Fetch Linear issue, save requirements, and create technical implementation plan
---

# /load - Load an Issue into Current Session

You are an expert technical planner who translates product requirements into actionable implementation plans.

**Prerequisites**: Linear MCP server must be configured in `.mcp.json`

## Usage

```
/load <id>
/load 277
/load ENG-277
```

## Workflow

### Phase 1: Setup

1. **Parse Issue ID**:
   - Extract the issue prefix from existing issues or the Linear workspace
   - If numeric only (e.g., `277`), prefix with detected project prefix
   - Normalize to uppercase: `{PREFIX}-{number}`

2. **Check for Existing Work**:
   ```bash
   git branch -a | grep -i "{issue-id}"
   gh pr list --search "{ISSUE-ID}" --json number,title,url,headRefName
   ls issues/*{number}* specs/*{number}* 2>/dev/null
   ```
   If found: Report what exists, ask user to continue or start fresh.

### Phase 2: Process Issue (Recursive)

Call `ProcessIssue({ISSUE-ID}, isRoot=true)`:

```
ProcessIssue(issueId, isRoot):
    1. Fetch issue from Linear:
       linear_get_issue(id: issueId)
       Extract: title, description, state, assignee, project, labels, children

    2. If issue has children:
       - List all children to user
       - For each child in order:
           ProcessIssue(childId, isRoot=false)  // recurse
       - After all children done, create parent summary files (see below)
       - Return

    3. Draft product requirements (issues/{ISSUE-ID}.md):
       ```markdown
       # {ISSUE-ID}: {Title}

       ## Summary
       {2-3 sentence business description}

       ## User Stories
       - As a {role}, I want {feature} so that {benefit}

       ## Acceptance Criteria
       - [ ] {Criterion 1}
       - [ ] {Criterion 2}

       ## Business Rules
       - {Rule 1}

       ## Out of Scope
       - {What this issue does NOT include}
       ```
       DO NOT include: File paths, code snippets, architecture details.

    4. Show product requirements to user:
       - Display the drafted issue file content
       - Ask: "Does this capture the product requirements for {ISSUE-ID}? (approve / modify / skip)"
       - Wait for approval; if modify, update and show again
       - If skip, return (no spec created)

    5. Research codebase:
       - Analyze relevant code that will be affected
       - Identify existing patterns and utilities
       - Look for similar implementations as references
       - Check for potential conflicts or dependencies

    6. Draft technical spec (specs/{issue-id-lowercase}.md):
       ```markdown
       # {ISSUE-ID}: {Title} - Technical Spec

       > See [{ISSUE-ID}](../issues/{ISSUE-ID}.md) for product requirements.

       ## Architecture Overview
       {High-level approach and key decisions}

       ## Implementation Plan

       ### 1. {First task}
       - Files: `path/to/file.py`
       - Changes: {what changes}

       ### 2. {Second task}
       ...

       ## Data Models / API Contracts
       {If applicable}

       ## Edge Cases & Error Handling
       - {Edge case 1}: {How handled}

       ## Testing Strategy
       - Unit tests: {what to test}
       - Integration tests: {what to test}

       ## Open Questions
       - [ ] {Question 1}
       ```

    7. Show technical spec to user:
       - Display the drafted spec file content
       - Ask: "Does this implementation plan for {ISSUE-ID} look correct? (approve / modify)"
       - Wait for approval; if modify, update and show again

    8. Update Linear (non-root issues only):
       - If NOT isRoot:
           linear_update_issue(issueId, description: "{content from issues file}")
       - Root/parent issues are NOT updated in Linear

    9. Report:
       ✓ {ISSUE-ID}: {Title} - approved{", Linear updated" if not isRoot}
```

#### Parent Summary Files (for issues with children)

After all children are processed, create parent files:

**Parent Issue File** (`issues/{PARENT-ID}.md`):
```markdown
# {PARENT-ID}: {Title}

## Summary
{High-level description of this parent feature/epic}

## Child Issues
- [{CHILD-1-ID}](./CHILD-1-ID.md): {Child 1 Title}
- [{CHILD-2-ID}](./CHILD-2-ID.md): {Child 2 Title}

## Acceptance Criteria
- [ ] All child issues completed
```

**Parent Spec File** (`specs/{parent-id}.md`):
```markdown
# {PARENT-ID}: {Title} - Technical Spec

> See [{PARENT-ID}](../issues/{PARENT-ID}.md) for requirements overview.

## Architecture Overview
{How child issues fit together, shared patterns, integration points}

## Child Specs
- [specs/{child-1-id}.md]: {Brief description}
- [specs/{child-2-id}.md]: {Brief description}

## Implementation Order
{Recommended sequence for implementing children, noting dependencies}

## Integration Points
{How children connect, shared state, API contracts between them}
```

### Phase 3: Final Summary

Present overall summary:
- Feature description (2-3 sentences)
- All files created
- Numbered implementation steps
- Complexity estimate (Low/Medium/High)
- Ask: proceed, modify, or discuss?

## Output Format

### Leaf Issue (No Children)

```
## {ISSUE-ID}: {Title}

**Status**: {New issue / Existing branch found / PR already open}

**Summary**: Brief description of what this feature accomplishes.

**Files saved**:
- `issues/{ISSUE-ID}.md` - Product requirements
- `specs/{issue-id}.md` - Technical specification

**Implementation Plan**:
1. {First task}
2. {Second task}
...

**Estimated complexity**: {Low/Medium/High}

Would you like me to proceed with this plan?
```

### Parent Issue (Has Children)

**Initial detection**:
```
## {ISSUE-ID}: {Title} (Parent Issue)

This issue has {N} child issues. I'll process each one sequentially,
asking for your approval on both product requirements and technical spec
before moving to the next.

**Child Issues**:
1. {CHILD-1-ID}: {Child 1 Title}
2. {CHILD-2-ID}: {Child 2 Title}
...

Starting with {CHILD-1-ID}...
```

**Per-issue approval flow** (recursive, for each issue):
```
---
## Processing: {ISSUE-ID}: {Title}

### Product Requirements (issues/{ISSUE-ID}.md)

{Full content of the drafted issue file}

Does this capture the product requirements for {ISSUE-ID}? (approve / modify / skip)
```

After approval:
```
### Technical Specification (specs/{issue-id}.md)

{Full content of the drafted spec file}

Does this implementation plan for {ISSUE-ID} look correct? (approve / modify)
```

After approval:
```
✓ {ISSUE-ID}: {Title} - approved, Linear updated

{Moving to next issue or "All children complete, creating parent files..."}
```

**Final summary**:
```
## {ROOT-ISSUE-ID}: {Title} - Complete

**Issues Processed** (Linear updated for each leaf):
✓ {CHILD-1-ID}: {Child 1 Title}
✓ {CHILD-2-ID}: {Child 2 Title}
⊘ {CHILD-3-ID}: {Child 3 Title} (skipped)

**Files Created**:
- `issues/{ROOT-ID}.md` - Root overview (local only)
- `specs/{root-id}.md` - Root coordination spec
- `issues/{CHILD-1-ID}.md`, `specs/{child-1-id}.md` → synced to Linear
- `issues/{CHILD-2-ID}.md`, `specs/{child-2-id}.md` → synced to Linear

**Estimated complexity**: {Low/Medium/High}

Would you like me to proceed with implementation?
```

## Error Handling

- **Linear MCP not available**: Report error, ask user to configure `.mcp.json`
- **Issue not found**: Inform user, suggest checking the issue ID
- **Existing work conflicts**: Present options to user
