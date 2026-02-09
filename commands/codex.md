---
description: Open Codex CLI agent in a new iTerm2/tmux session with issue context — implements spec or verifies work
---
# /codex - Open Codex Agent with Issue Context

### Step 1: Detect Issue Context
```bash
CURRENT_DIR=$(pwd)
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
ISSUE_ID=$(echo "${BRANCH_NAME}" | grep -oE '^[A-Za-z]+-[0-9]+' | tr '[:lower:]' '[:upper:]')
```

### Step 2: Gather Context
If `ISSUE_ID` found:
- Read `issues/${ISSUE_ID}.md` if it exists
- Read `specs/${ISSUE_ID,,}.md` (lowercased) if it exists — try glob `specs/*${ISSUE_ID,,}*` as fallback
- Check for implementation work:
```bash
BASE_BRANCH=$(git merge-base HEAD origin/staging 2>/dev/null || git merge-base HEAD origin/main 2>/dev/null)
DIFF_STAT=$(git diff --stat "${BASE_BRANCH}"..HEAD -- ':!issues/' ':!specs/' 2>/dev/null)
```

### Step 3: Determine Mode
- **Verify mode**: `DIFF_STAT` is non-empty (code changes exist beyond issue/spec files)
- **Implement mode**: `DIFF_STAT` is empty or no implementation changes yet

### Step 4: Build Prompt
**Implement mode** — build prompt from spec + issue:
```
CODEX_PROMPT="Implement the following feature. Follow the spec exactly.

$(cat specs/*${ISSUE_ID,,}* 2>/dev/null || cat issues/${ISSUE_ID}.md 2>/dev/null || echo "Branch: ${BRANCH_NAME}")

Work incrementally — make one change at a time and verify it compiles/passes before moving on."
```

**Verify mode** — build prompt from diff + spec:
```
CODEX_PROMPT="Review and verify the implementation on this branch. Check against the spec and acceptance criteria.

$(cat specs/*${ISSUE_ID,,}* 2>/dev/null || cat issues/${ISSUE_ID}.md 2>/dev/null || echo "Branch: ${BRANCH_NAME}")

Verify:
1. All acceptance criteria are met
2. No obvious bugs or edge cases missed
3. Tests exist and cover the key paths
4. Code follows existing patterns in the codebase

Report what's done, what's missing, and any issues found."
```

**No issue context** — just open codex with no prompt (bare mode).

### Step 5: Launch in Tmux
```bash
SESSION_NAME="codex-$(basename "${CURRENT_DIR}")"
tmux kill-session -t "${SESSION_NAME}" 2>/dev/null || true

FOLDER_NAME=$(basename "${CURRENT_DIR}")
tmux new-session -d -s "${SESSION_NAME}" -c "${CURRENT_DIR}"
tmux set-option -t "${SESSION_NAME}" status-left "[${FOLDER_NAME}] "
tmux set-option -t "${SESSION_NAME}" status-left-length 50
```

If prompt exists, write it to a temp file and launch codex with it:
```bash
PROMPT_FILE=$(mktemp /tmp/codex-prompt-XXXXX.txt)
echo "${CODEX_PROMPT}" > "${PROMPT_FILE}"
tmux send-keys -t "${SESSION_NAME}" "codex \"$(cat ${PROMPT_FILE})\"" Enter
rm -f "${PROMPT_FILE}"
```

Otherwise just launch bare:
```bash
tmux send-keys -t "${SESSION_NAME}" "codex" Enter
```

Open iTerm window:
```bash
osascript -e "
tell application \"iTerm\"
    activate
    set newWindow to (create window with default profile)
    tell current session of newWindow
        write text \"tmux attach -t ${SESSION_NAME}\"
    end tell
end tell
"
```

**Output**: Report mode (Implement/Verify/Bare), issue ID if found, tmux session name.
