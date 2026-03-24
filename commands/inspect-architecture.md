---
description: Inspect architecture docs against codebase and report drift
---
# /inspect-architecture - Architecture Drift Inspector

Read-only. Reports mismatches between `docs/architecture/*.md` and the codebase, with mitigation prompts for each gap.

## What "Architecture" Means

Architecture = the **shape of the system**: what components exist, how they connect, what structural patterns they follow.

| Layer | Scope | Check? |
|-------|-------|--------|
| **Architecture** | Components/services, communication patterns, structural rules, layer ownership | ✅ Yes |
| **Product** | Features, business rules, user stories | ❌ No |
| **Implementation** | Function names, config values, timeouts, data formats, internal logic | ❌ No |

**Flag these:**
- A documented service/daemon doesn't exist (or vice versa)
- A documented communication pattern isn't followed (e.g., doc: worker uses direct DB; code: worker calls API over HTTP)
- A structural rule is violated (e.g., doc: screens dispatch actions only; code: screen calls daemon RPC directly)
- A documented layer is missing (e.g., doc: every XD screen has a presenter; new screen has none)

**Don't flag these:** config value changed, function renamed, new feature added to existing service, internal logic changed.

## Process

### Phase 1: Read Architecture Docs

```bash
ls docs/architecture/*.md
```

If none found: report and exit. Read all docs — understand the intended system shape.

### Phase 2: Verify Claims

For each architecture doc, extract claims about system shape and structural patterns, then verify against code. Classify each:
- **PASS** — code matches
- **WARN** — possible drift, needs judgment
- **FAIL** — clear contradiction

### Phase 3: Report

```
Architecture Inspection: {repo}
======================================================================
docs/architecture/{file}.md
  PASS  {claim} — {evidence}
  WARN  {claim} — doc says {X}, code shows {Y}
  FAIL  {claim} — doc says {X}, but {actual}
----------------------------------------------------------------------
Summary: {N} PASS, {N} WARN, {N} FAIL
```

### Phase 4: Mitigate

For each WARN or FAIL, AskUserQuestion — Header: "Architecture Drift", describe the gap, options: "Update doc", "Fix code", "Skip".

When called from `/finish`: Phase 1–3 only, no prompts. FAIL findings block proceeding.
