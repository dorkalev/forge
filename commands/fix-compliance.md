---
description: Fix SOC2 compliance failures from CI check
---
# /fix-compliance - Fix SOC2 Compliance Failures

Fixes common SOC2 CI failures: invalid tickets, ghost tickets (listed but no code), inherited merge tickets, missing tickets.

```
/fix-compliance
/fix-compliance --tickets "PROJ-123,PROJ-456"
```

**Compliance model**: `Linear Tickets ←→ PR Description ←→ Code Changes`. Every change must trace to a ticket. File-level documentation is NOT required — ticket linkage is what matters.

### Phase 1: Analyze Current State
```bash
BRANCH=$(git branch --show-current)
gh pr view --json body,number,title -q '.'
```
Tickets from this branch's own commits: `git log staging..HEAD --no-merges --first-parent --format="%s%n%b" | grep -oE "[A-Z]+-[0-9]+" | sort -u`
Tickets inherited from merging staging (should NOT be in PR): compare `git log staging..HEAD --no-merges` vs `git log staging..HEAD --no-merges --first-parent` — any commits in the first but not the second came from staging merges. Extract their tickets to exclude.
**IMPORTANT:** `--first-parent` ensures only commits authored on this branch are included. Without it, merging origin/staging pulls in all staging commits (e.g., BOL-449, BOL-452) and pollutes the ticket list.
Parse current PR Linear Tickets table.

### Phase 2: Identify Gaps
Compare: commit tickets vs PR table, merge tickets to exclude, verify each against Linear.

### Phase 3: Resolve Each Gap
- **Missing tickets**: Add to Linear Tickets table
- **Inherited (from merges)**: Remove from table
- **Invalid**: Check if typo, fix or remove
- **No tickets at all**: AskUserQuestion — "Create new ticket" or "Link to existing"

### Phase 4: Build Updated PR Body
Construct with: TL;DR, Linear Tickets table (`| Ticket | Title | Status |`), Product Requirements (from issues/ or Linear), Acceptance Criteria table, Technical Implementation, Testing & Verification, Audit Trail.

### Phase 5: Update PR
```bash
cat > /tmp/pr_body.md << 'EOF'
{constructed body}
EOF
gh pr edit {number} --body-file /tmp/pr_body.md
```

### Phase 6: Verify
Pass when: every PR ticket exists in Linear, no orphan tickets, no merge commit tickets.

## Error Handling
- **No PR found**: suggest `gh pr create` | **Linear MCP not configured**: fall back to manual links | **Complex conflicts**: ask user
