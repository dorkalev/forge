---
description: Create a Linear issue from planning discussion and save issue/spec files
---
# /capture - Turn Planning Discussion into a Linear Issue

**Prerequisites**: Linear MCP configured in `.mcp.json`

Run after discussing and planning a feature in the conversation.

### Phase 1: Extract Planning Context
Review conversation to identify: feature name/title, product requirements (WHAT & WHY), technical spec (HOW).

### Phase 2: Prompt for Metadata
AskUserQuestion: Priority (Urgent/High/Medium/Low/None), Labels (comma-separated or "none").

### Phase 3: Create Linear Issue
`linear_create_issue(title, description, teamId, priority)` — Priority: 0=None, 1=Urgent, 2=High, 3=Medium, 4=Low.

### Phase 4: Save Product Requirements
Create `issues/{ISSUE_ID}-{number}.md`:
```markdown
# {ISSUE_ID}-{number}: {Title}
**Priority:** {Priority}  **State:** Backlog  **URL:** {url}
## Summary
{2-3 sentence business description}
## User Stories
- As a {role}, I want {feature} so that {benefit}
## Acceptance Criteria
- [ ] {Criteria}
## Business Rules
- {Rules}
## Out of Scope
- {Exclusions}
```
DO NOT include file paths, code snippets, or architecture details.

### Phase 5: Save Technical Spec
Create `specs/{issue}-{number}-{feature-name}.md`:
```markdown
# {ISSUE-ID}: {Title} - Technical Spec
> See [{ISSUE-ID}](../issues/{ISSUE-ID}.md) for product requirements.
## Overview
## Architecture
## Implementation Plan
### 1. {Task} — Files: `path`, Changes: {what}
## Edge Cases & Error Handling
## Testing Strategy
## Open Questions
```

### Phase 6: Output
Report: Linear issue URL, files saved (issues/ and specs/), next steps (create branch or `/start`).

## Error Handling
- **Linear MCP not available**: ask user to configure `.mcp.json`
- **No clear feature**: ask user to clarify
- **Issue creation fails**: don't create local files, report error
