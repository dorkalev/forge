---
description: Fix SOC2 compliance failures from CI check
---

# /fix-compliance - Fix SOC2 Compliance Failures

You are an elite DevOps Compliance Engineer. The SOC2 compliance check in CI failed, and you need to fix the PR to pass.

## Usage

```
/fix-compliance
/fix-compliance --files "path/to/file1.py,path/to/file2.py"
/fix-compliance --tickets "BOL-123,BOL-456"
```

## What This Command Does

This command fixes common SOC2 compliance failures:

1. **Undocumented code changes** - Files changed but not in PR's Key Changes table
2. **Invalid tickets** - Tickets referenced but don't exist in Linear
3. **Ghost tickets** - Tickets listed but no corresponding code changes
4. **Inherited tickets** - Tickets that came from merge commits

## SOC2 Compliance Model

The PR description is the **central junction** for audit traceability:

```
Linear Tickets ←→ PR Description ←→ Code Changes
       ↕                                    ↕
  issues/*.md                          specs/*.md
```

Every code change must trace back to a Linear ticket. The PR is the audit record.

## Workflow

### Phase 1: Analyze Current State

1. Get current PR body:
   ```bash
   BRANCH=$(git branch --show-current)
   gh pr view --json body,number,title -q '.'
   ```

2. Get changed files:
   ```bash
   git diff staging...HEAD --name-only
   ```

3. Get tickets from commits (excluding merge commits):
   ```bash
   git log staging..HEAD --no-merges --format="%s%n%b" | grep -oE "[A-Z]+-[0-9]+" | sort -u
   ```

4. Parse current PR Key Changes table (if exists)

### Phase 2: Identify Gaps

Compare:
- Files in diff vs files in Key Changes table
- Tickets in commits vs tickets in Linear Tickets table
- Tickets in PR vs actual Linear issues

Build a gap report:
```
UNDOCUMENTED FILES:
- web/backoffice/api_routes.py
- algo/scripts/migrate_npz.py

TICKETS IN COMMITS BUT NOT IN PR:
- BOL-407

FILES WITHOUT TICKET MAPPING:
- infra/terraform/*.tf (no ticket covers infra changes)
```

### Phase 3: Resolve Each Gap

For each undocumented file, determine appropriate action:

**Option A: Map to existing ticket**
If the file change is part of an existing ticket's scope:
- Add to Key Changes table with that ticket

**Option B: Create new ticket**
If the file change is unrelated to existing tickets:
```
Use AskUserQuestion:
- Header: "New Ticket"
- Question: "File {file} doesn't fit any ticket. Create one?"
- Options:
  - "Create ticket for: {suggested description}"
  - "Add to existing ticket: {primary_ticket}"
  - "Skip (leave undocumented)"
```

If creating ticket:
1. Create `issues/{NEW-TICKET}.md` with summary
2. Create ticket in Linear via MCP
3. Add to PR's Linear Tickets table

**Option C: Expected change (infra/config)**
For infrastructure, config, or CI files that don't need formal tickets:
- Add to Key Changes with description "Infrastructure/Configuration"
- Use primary ticket or "N/A" as ticket reference

### Phase 4: Build Updated PR Body

Construct the complete PR body following this structure:

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
{From issues/{TICKET}.md}

### Acceptance Criteria
| # | Criterion | Status | Verification |
|---|-----------|--------|--------------|
| 1 | ... | [x] Done | Test: test_file.py |

---

## Technical Implementation

### Key Changes
| File | Change | Ticket | Description |
|------|--------|--------|-------------|
| `path/to/file.py` | Modified | {TICKET} | What it does |
| `path/to/new.py` | Added | {TICKET} | What it does |

---

## Testing & Verification
| Type | Status | Details |
|------|--------|---------|
| Unit | Passed | X tests |
| Integration | Passed | Pipeline verified |

---

## Audit Trail
- All changes documented and linked to tickets
```

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

Wait for CI to re-run, or manually verify:
- Every changed file appears in Key Changes table
- Every ticket in Key Changes exists in Linear Tickets table
- No orphan tickets (listed but no code)

## Quick Fix Mode

If called with `--files` parameter, skip analysis and just add those files:

```bash
/fix-compliance --files "web/api.py,algo/process.py"
```

This will:
1. Read current PR body
2. Add specified files to Key Changes table
3. Use primary ticket from PR
4. Update PR

## Examples

### Example 1: Undocumented files
```
SOC2 check failed: web/backoffice/middleware.py not in PR description

/fix-compliance
→ Adds middleware.py to Key Changes table
→ Updates PR
→ CI re-runs and passes
```

### Example 2: Inherited tickets
```
SOC2 check failed: BOL-335 has no code changes (from merge commit)

/fix-compliance
→ Detects BOL-335 came from merging staging
→ Removes from Linear Tickets table
→ Updates PR
```

### Example 3: New unrelated work
```
SOC2 check failed: infra/terraform/cloud-run.tf not documented

/fix-compliance
→ Detects terraform changes aren't covered by any ticket
→ Asks: "Create ticket for Terraform Cloud Run config?"
→ User: "Add to BOL-407"
→ Adds to Key Changes with BOL-407
→ Updates PR
```

## Error Handling

- **No PR found**: Report error, suggest running `gh pr create`
- **Linear MCP not configured**: Fall back to manual ticket links
- **Complex conflicts**: Ask user to resolve manually
