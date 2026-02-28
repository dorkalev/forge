---
description: Fix SOC2 compliance failures from CI check
---
# /fix-compliance - Fix SOC2 Compliance Failures

Fixes SOC2 CI failures by reading the ACTUAL CI check output and compliance bot comment.

```
/fix-compliance
/fix-compliance --tickets "PROJ-123,PROJ-456"
```

**Compliance model**: `Linear Tickets ←→ PR Description ←→ Code Changes`. Every change must trace to a ticket.

## Phase 0: Read CI Status and Compliance Comment (MANDATORY FIRST STEP)

**DO NOT SKIP THIS PHASE. DO NOT do your own manual analysis first. START HERE.**

**Step 1: Check CI status:**
```bash
gh pr checks {pr-number} 2>&1 | grep -i "ticket\|spec\|compliance\|check"
```
If the compliance check passes → nothing to fix, exit immediately.

**Step 2: Get the latest compliance comment from the PR:**
```bash
gh api repos/{owner}/{repo}/issues/{pr-number}/comments --paginate --jq '
  [.[] | select(.user.login == "github-actions[bot]" and (.body | contains("SOC2 Compliance")))] | last | .body'
```
Parse the comment:
- `## ✅ SOC2 Compliance: Passed` → nothing to fix, exit
- `## ❌ SOC2 Compliance: Failed` → continue
- Extract `run_id` from the `<sub>` tag at bottom: `[run {run_id}](...)`
- Read the **"What Failed"** section — this tells you exactly what to fix

**Step 3: Get SPECIFIC failures from the run logs (the comment only has summaries):**
```bash
# Extract detailed failure info from the run
gh run view {run_id} --log-failed 2>&1 | grep -E "##\[group\]|##\[error\]|  - |  →|Recommendations" | head -60
```

This gives structured output:
- `##[error]` → failure summary (e.g., `invalid_tickets, unspecced_changes`)
- `##[group]Unspecced Changes (N)` → `  - path/to/file: reason`
- `##[group]Invalid Tickets (N)` → `  - TICKET: reason`
- `##[group]Missing Documentation (N)` → `  - TICKET: reason`
- `##[group]Issues (N)` → general problems
- `Recommendations:` → `  → specific action`

**Step 4: Extract specific data if needed:**
```bash
gh run view {run_id} --log-failed 2>&1 | sed -n '/Unspecced Changes/,/endgroup/p' | grep "  - "
gh run view {run_id} --log-failed 2>&1 | sed -n '/Missing Documentation/,/endgroup/p' | grep "  - "
gh run view {run_id} --log-failed 2>&1 | grep "  →"
```

## Phase 1: Fix Each Issue Found in Phase 0

Work through the SPECIFIC issues identified in the compliance comment and run logs:

### For `unspecced_changes`:
The compliance checker validates that every changed file in the diff is covered by a ticket description in the PR body.
1. Read each unspecced file from the run log
2. Determine which ticket it belongs to (usually obvious from file path)
3. Mention the file explicitly in the PR body's Technical Implementation section under the relevant ticket
4. For lockfiles (`uv.lock`, `package-lock.json`): mention them under the ticket that changed dependencies (e.g., "All `uv.lock` files regenerated for Python 3.14")

### For `invalid_tickets`:
- Verify the ticket exists in Linear (use MCP `get_issue`)
- If it exists but CI says invalid: may be a transient API issue, re-push to retry
- If genuinely invalid: remove from PR table

### For `ghost_tickets` / `unimplemented_tickets`:
- Tickets listed in PR but with no code changes matching them
- Either: remove the ticket from the PR table, OR explain the ticket's coverage in the description

### For `missing_documentation`:
- `TICKET: no issues/ file found` → Create `issues/{TICKET}.md` (non-technical product requirements)
- `TICKET: no specs/ file found` → Create `specs/{feature-name}.md` (technical spec)
- Fetch ticket from Linear for content, keep issues/ non-technical

### For spec inconsistencies:
- If the compliance checker says "spec says X but PR says Y" → update the spec to match current reality

### For acceptance criteria issues:
- If acceptance criteria are unchecked in Linear → update the Linear ticket to check them off
- If test plan items are wrong → update the PR body

## Phase 2: Update PR Body

Ensure the PR body includes ALL of these:
1. **Summary** — 1-2 sentence overview
2. **Linear Tickets** table (`| Ticket | Title | Status |`)
3. **Changes** — organized by ticket, must mention ALL changed files
4. **Test Plan** — checklist of verification items

**The Changes section is what the compliance checker validates most strictly.** Every file in the diff must be traceable to a ticket through this section.

## Phase 3: Commit, Push, and Update PR
```bash
# Commit any new files (issues/specs)
git add issues/ specs/
git commit -m "BOL-XXX: Add compliance documentation"
git push

# Update PR body
cat > /tmp/pr_body.md << 'EOF'
{constructed body}
EOF
gh pr edit {number} --body-file /tmp/pr_body.md
```

## Phase 4: Verify
Wait for CI to re-run. Check the NEW compliance comment:
```bash
gh pr checks {pr-number} --watch --fail-fast
```
If it fails again → go back to Phase 0 with the NEW comment/logs.

## Error Handling
- **No PR found**: suggest `gh pr create`
- **Linear MCP not configured**: fall back to manual links
- **No compliance comment yet**: wait for CI
- **Gemini rate limited in CI**: wait and re-push to trigger re-run
