---
description: Fix SOC2 compliance failures from CI check
---

# /fix-compliance - Fix SOC2 Compliance Failures

You are an elite DevOps Compliance Engineer. The SOC2 compliance check in CI failed, and you need to fix the PR to pass.

## Usage

```
/fix-compliance
/fix-compliance --tickets "PROJ-123,PROJ-456"
```

## What This Command Does

This command fixes common SOC2 compliance failures:

1. **Invalid tickets** - Tickets referenced but don't exist in Linear
2. **Ghost tickets** - Tickets listed but no corresponding code changes
3. **Inherited tickets** - Tickets that came from merge commits (should be removed)
4. **Missing tickets** - Code changes without any ticket reference

## SOC2 Compliance Model

The PR description is the **central junction** for audit traceability:

```
Linear Tickets ←→ PR Description ←→ Code Changes
       ↕
  issues/*.md
```

Every code change must trace back to a Linear ticket. The PR is the audit record.

**Note**: File-level documentation is NOT required. You don't need a list of every file changed in the PR description. What matters is that tickets are properly linked and each ticket describes the scope of work.

## Workflow

### Phase 1: Analyze Current State

1. Get current PR body:
   ```bash
   BRANCH=$(git branch --show-current)
   gh pr view --json body,number,title -q '.'
   ```

2. Get tickets from commits (excluding merge commits):
   ```bash
   git log staging..HEAD --no-merges --format="%s%n%b" | grep -oE "[A-Z]+-[0-9]+" | sort -u
   ```

3. Get tickets from merge commits (these should NOT be in PR):
   ```bash
   git log staging..HEAD --merges --format="%s%n%b" | grep -oE "[A-Z]+-[0-9]+" | sort -u
   ```

4. Parse current PR Linear Tickets table (if exists)

### Phase 2: Identify Gaps

Compare:
- Tickets in non-merge commits vs tickets in Linear Tickets table
- Tickets from merge commits that shouldn't be included
- Tickets in PR vs actual Linear issues (verify they exist)

Build a gap report:
```
TICKETS IN COMMITS BUT NOT IN PR:
- PROJ-407

TICKETS FROM MERGE COMMITS (remove these):
- PROJ-335

INVALID TICKETS (not found in Linear):
- PROJ-999
```

### Phase 3: Resolve Each Gap

**Missing tickets**: Add to Linear Tickets table

**Inherited tickets (from merges)**: Remove from Linear Tickets table

**Invalid tickets**:
- Check if typo, fix if so
- Otherwise remove from PR

**No tickets at all**:
```
Use AskUserQuestion:
- Header: "No Ticket"
- Question: "No ticket found for this work. What should we do?"
- Options:
  - "Create new ticket: {suggested description}"
  - "Link to existing ticket: {enter ticket ID}"
```

### Phase 4: Build Updated PR Body

Construct the PR body following this structure:

```markdown
# {PRIMARY-TICKET}: {Title}

## TL;DR
One sentence describing the change.

---

## Linear Tickets
| Ticket | Title | Status |
|--------|-------|--------|
| [{TICKET}](https://linear.app/team/issue/{TICKET}) | {title} | {status} |

---

## Product Requirements

### Summary
{From issues/{TICKET}.md or Linear description}

### Acceptance Criteria
| # | Criterion | Status | Verification |
|---|-----------|--------|--------------|
| 1 | ... | [x] Done | Test: test_file.py |

---

## Technical Implementation

### Changed Files
| File | Change | Description |
|------|--------|-------------|
| `path/to/file.py` | Modified | What it does |

### Notable Decisions
- **Decision**: {What was decided}
- **Rationale**: {Why}

---

## Testing & Verification
| Type | Status | Details |
|------|--------|---------|
| Unit | Passed | X tests |

---

## Audit Trail
- All changes linked to tickets
```

**Note**: The "Changed Files" table is optional and for documentation purposes only. It is NOT required for SOC2 compliance. What matters is the Linear Tickets table.

### Phase 5: Update PR

```bash
# Save body to file
cat > /tmp/pr_body.md << 'EOF'
{constructed body}
EOF

# Update PR
gh pr edit {number} --body-file /tmp/pr_body.md
```

### Phase 6: Verify Fix

The compliance check will pass when:
- Every ticket in PR exists in Linear
- No orphan tickets (listed but no code)
- No merge commit tickets included

## Examples

### Example 1: Missing ticket in PR
```
SOC2 check failed: PROJ-407 found in commits but not in PR description

/fix-compliance
→ Adds PROJ-407 to Linear Tickets table
→ Updates PR
→ CI re-runs and passes
```

### Example 2: Inherited tickets from merge
```
SOC2 check failed: PROJ-335 has no code changes (from merge commit)

/fix-compliance
→ Detects PROJ-335 came from merging staging
→ Removes from Linear Tickets table
→ Updates PR
```

### Example 3: Invalid ticket
```
SOC2 check failed: PROJ-999 not found in Linear

/fix-compliance
→ Checks if typo (PROJ-399?)
→ Asks user to confirm
→ Fixes or removes
→ Updates PR
```

## Error Handling

- **No PR found**: Report error, suggest running `gh pr create`
- **Linear MCP not configured**: Fall back to manual ticket links
- **Complex conflicts**: Ask user to resolve manually
