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

**CRITICAL**: Extract `ISSUE_ID` and `URL` from the API response. Use ONLY the returned identifier — NEVER fabricate or guess an issue ID. Do NOT proceed to Phase 4 until the issue exists in Linear.

### Phase 4: Post Spec to Linear
Post the technical spec as a comment on the newly created issue:
```markdown
## Technical Spec

### Overview
{from conversation}

### Architecture
{from conversation}

### Implementation Plan
1. {Task} — Files: `path`, Changes: {what}

### Edge Cases & Error Handling
{from conversation}

### Testing Strategy
{from conversation}

### Open Questions
{from conversation}
```
`linear_save_comment(issueId: ISSUE_ID, body: spec_content)`

DO NOT save any local files (no issues/ or specs/ directories).

### Phase 5: Output
Report: Linear issue URL, spec posted as comment, next steps (create branch or `/start`).

## Error Handling
- **Linear MCP not available**: ask user to configure `.mcp.json`
- **No clear feature**: ask user to clarify
- **Issue creation fails**: don't post spec, report error
