---
description: Prove a ticket actually works by driving the app in a real browser as the user, collecting screenshot evidence, auto-fixing breakage, and posting the verified user story to Linear.
---
# /verify - Prove the Implementation Works (Browser Evidence Loop)

Simulate the user/"hacker" against the running app, gather evidence per acceptance
criterion, **auto-fix breakage (capped retries)**, and post the verified user story +
screenshots to the Linear ticket on success.

> Not to be confused with `/forge:verify-pr` (SOC2 PR compliance document). This command
> drives a real browser and proves the feature behaves as specified.

**Prerequisites**
- Playwright MCP configured (`mcp__plugin_playwright_playwright__*` tools available)
- Linear MCP configured in `.mcp.json`
- App runs locally (dev server) for web tickets

```
/verify                  # infer issue ID from current branch
/verify PROJ-277
/verify PROJ-277 --unattended   # dispatched-agent mode; never prompts (no-op flag, already non-interactive)
```

---

### Phase 1: Resolve Issue & Load Acceptance Criteria

1. **Issue ID**: from argument, else parse from branch (`git rev-parse --abbrev-ref HEAD` → leading `{ID}` per `{ID}-{slug}` convention). Ignore a `--unattended` token if present — it is a mode flag, not the ID (and a no-op here, since this command never prompts).
2. `linear_get_issue(id)` → extract **User Stories** and **Acceptance Criteria** from the description and spec comment.
3. **Each acceptance criterion becomes one verification case.** If a criterion is not browser-observable (pure backend), note it as "not browser-verifiable here" and skip — don't fake evidence.

If there are zero browser-observable criteria → report that and stop (nothing to prove in a browser).

### Phase 2: Start the App

1. Detect run command: read `package.json` scripts (`dev`/`start`), or a `.forge`/README hint.
2. Start the dev server **in the background** and capture the local URL (e.g. `http://localhost:3000`). Capture server logs to a file so you can correlate browser failures with server errors.
3. Wait until it actually serves (poll the URL / `browser_wait_for`), not just that the process started.

### Phase 3: Build the Verification Plan

For each criterion, write a concrete **user-story script** — the steps a real user (or a probing "hacker") would take:
- Entry route, the interactions (clicks, form fills, key presses), and the **observable success condition** (text appears, element state, URL change, network 2xx).
- Include at least one adversarial check per story where sensible (empty input, invalid value, unauthorized access) — proving it doesn't just work on the happy path.

### Phase 4: Execute & Collect Evidence

Drive the browser with Playwright MCP. Per story:
1. `browser_navigate` to the route → `browser_wait_for` load.
2. `browser_snapshot` to read the accessibility tree (find elements).
3. Interact: `browser_click`, `browser_fill_form`, `browser_type`, `browser_press_key`, `browser_select_option`.
4. **Capture evidence**:
   - `browser_take_screenshot` → save to `.forge-evidence/{ID}/{case}.png`
   - `browser_console_messages` → record errors/warnings
   - `browser_network_requests` → record failed (4xx/5xx) or pending requests
5. **Judge pass/fail** against the criterion's observable success condition. Record: criterion, steps taken, result, screenshot path, any console/network anomalies.

Use the browser+server correlation table when a page hangs or blanks: spinner-forever + no server invocation → wrong fetch URL; blank + clean build → hydration/data; pending request + 5xx in logs → server error (read the server log, it has the real stack).

### Phase 5: Auto-Fix Loop (capped)

If any case **fails**:
1. Diagnose using the captured evidence (browser state + server logs).
2. Fix the implementation in code.
3. Restart the dev server if needed and **re-run only the failed cases**.
4. Repeat — **max 3 total cycles**. After the cap, stop and report remaining failures honestly with their evidence. **Never loop infinitely; never mark a failing case as passed.**

Log every dropped/uncovered case explicitly — silent truncation reads as "all verified" when it wasn't.

Evidence files are artifacts, not deliverables: ensure `.forge-evidence/` is in the **target repo's** `.gitignore` (append it if missing) so screenshots are never swept into a commit by `/forge:finish`.

### Phase 6: Post Verified Story to Linear (on success)

Only when **all browser-verifiable criteria pass**. Upload screenshots **one at a time** — signed URLs expire in 60s and must NOT be batched (prepare → PUT → finalize one file before starting the next):

1. Get the file's exact byte size: `wc -c < .forge-evidence/{ID}/{case}.png`.
2. `prepare_attachment_upload(issue: {ID}, filename, contentType: "image/png", size)` → returns `assetUrl` + `uploadRequest{url, headers}`.
3. **Immediately** PUT the raw bytes outside MCP, sending **every** header in `uploadRequest.headers` verbatim (changing/omitting any, including casing → HTTP 403):
   ```bash
   curl -X PUT --data-binary @".forge-evidence/{ID}/{case}.png" \
     <each key:value from uploadRequest.headers, verbatim> \
     "<uploadRequest.url>"
   ```
   Do not base64-encode or transform the file.
4. After the PUT succeeds, `create_attachment_from_upload(issue: {ID}, assetUrl, title: "{case}")` to link it to the issue.
5. Only then prepare the next screenshot.
6. `save_comment(issueId: {ID}, body: ...)` with the structure below — embed each shot inline with `![{case}]({assetUrl})` (the `assetUrl` from step 2 renders as an image in Linear markdown):
   ```markdown
   ## ✅ Verified in browser — {ID}

   Driven against `{local URL}` on {date}. All acceptance criteria proven.

   ### User stories verified
   **As a {role}, I want {feature}…**
   1. {step} → {observed result}
   2. {step} → {observed result}
   ![{case}]({assetUrl})

   ### Adversarial checks
   - {invalid/empty/unauthorized case} → {handled as expected}

   ### Evidence
   - Console: no errors
   - Network: all requests 2xx
   - Screenshots attached above
   ```
7. Close the browser (`browser_close`) and stop the dev server.

### Phase 7: Report

State: issue ID, # criteria verified, # auto-fix cycles used, pass/fail per case, Linear comment URL. If anything remains unverified, say so plainly — do not round up to "done".

## Error Handling
- **Playwright MCP unavailable** → report; suggest installing the Playwright plugin.
- **Linear MCP unavailable** → still produce local evidence + report; skip the Linear post.
- **Dev server won't start** → capture the startup error, report, do not proceed to browser.
- **Criterion not browser-observable** → mark explicitly as skipped, never fabricate evidence.
