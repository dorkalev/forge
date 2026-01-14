---
description: Create a Linear ticket from planning discussion and save issue/spec files
---

# /ticketify - Turn Planning Discussion into a Linear Ticket

You are an expert at formalizing planning discussions into structured product requirements and technical specifications.

**Prerequisites**: Linear MCP server must be configured in `.mcp.json`

## Usage

```
/ticketify
```

Run this after discussing and planning a feature in the conversation.

## Workflow

### Phase 1: Extract Planning Context

Review the conversation to identify:
- **Feature name/title**: Clear, concise name
- **Product requirements**: User stories, acceptance criteria (WHAT & WHY)
- **Technical spec**: Architecture, implementation details (HOW)

### Phase 2: Prompt User for Metadata

Use `AskUserQuestion`:
1. **Priority**: Urgent, High, Medium, Low, None
2. **Labels**: Any labels to apply? (comma-separated or "none")

### Phase 3: Create Linear Ticket

Use Linear MCP to create the issue:
```
linear_create_issue(
  title: "<feature title>",
  description: "<product description in markdown>",
  teamId: "<team ID>",
  priority: <0-4>
)
```

Priority mapping: 0=None, 1=Urgent, 2=High, 3=Medium, 4=Low

### Phase 4: Save Product Requirements

Create `issues/{TICKET}-{number}.md`:
```markdown
# {TICKET}-{number}: {Title}

**Priority:** {Priority}
**State:** Backlog
**URL:** {ticket_url}

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
- {What this feature does NOT include}
```

**DO NOT include**: File paths, code snippets, architecture details.

### Phase 5: Save Technical Spec

Create `specs/{ticket}-{number}-{feature-name}.md`:
```markdown
# {TICKET}-{number}: {Title} - Technical Spec

> See [{TICKET}-{number}](../issues/{TICKET}-{number}.md) for product requirements.

## Overview
{High-level technical summary}

## Architecture
{System design, data flow}

## Implementation Plan

### 1. {First task}
- Files: `path/to/file.py`
- Changes: {what changes}

## Edge Cases & Error Handling
- {Edge case 1}: {How handled}

## Testing Strategy
- {How to verify}

## Open Questions
- [ ] {Unresolved questions}
```

### Phase 6: Output Summary

```
## Created: {TICKET}-{number}: {Title}

**Linear ticket**: {ticket_url}

**Files saved**:
- `issues/{TICKET}-{number}.md` - Product requirements
- `specs/{ticket}-{number}-{feature-name}.md` - Technical specification

**Next steps**:
- Create branch: `git checkout -b {ticket}-{number}-{feature-name}`
- Or use `/issues` to set up the full dev environment

Ready to implement!
```

## Error Handling

- **Linear MCP not available**: Report error, ask user to configure `.mcp.json`
- **No clear feature in conversation**: Ask user to clarify
- **Ticket creation fails**: Do not create local files, report the error
