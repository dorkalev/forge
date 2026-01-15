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

### Phase 0: Parse Issue ID

- Extract the issue prefix from existing issues or the Linear workspace
- If numeric only (e.g., `277`), prefix with detected project prefix
- Normalize to uppercase: `{PREFIX}-{number}`

### Phase 1: Check for Existing Work

```bash
git branch -a | grep -i "{issue-id}"
gh pr list --search "{ISSUE-ID}" --json number,title,url,headRefName
ls issues/*{number}* specs/*{number}* 2>/dev/null
```

If found: Report what exists, ask user to continue or start fresh.

### Phase 2: Fetch the Linear Issue

Use Linear MCP:
```
linear_get_issue(id: "{ISSUE-ID}")
```

Extract: title, description, state, assignee, project, labels.

### Phase 3: Save Product Requirements

**CRITICAL**: `issues/` files are PRODUCT documentation (WHAT & WHY), not technical.

Create/update `issues/{ISSUE-ID}.md`:
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

**DO NOT include**: File paths, code snippets, architecture details.

### Phase 4: Research the Codebase

- Analyze relevant code that will be affected
- Identify existing patterns and utilities
- Look for similar implementations as references
- Check for potential conflicts or dependencies
- Review related tests

### Phase 5: Create Technical Specification

**CRITICAL**: `specs/` files are TECHNICAL documentation (HOW).

Create/overwrite `specs/{issue-id-lowercase}.md`:
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

### Phase 6: Present the Plan

Summarize with:
- Feature description (2-3 sentences)
- Numbered implementation steps
- Complexity estimate (Low/Medium/High)
- Risks or areas needing input
- Ask: proceed, modify, or discuss?

## Output Format

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

**Questions/Risks**:
- {Any items needing clarification}

Would you like me to proceed with this plan?
```

## Error Handling

- **Linear MCP not available**: Report error, ask user to configure `.mcp.json`
- **Issue not found**: Inform user, suggest checking the issue ID
- **Existing work conflicts**: Present options to user
