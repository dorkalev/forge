---
description: Open Codex CLI agent in a new iTerm2/tmux session
---

# /codex - Open Codex Agent

Opens Codex CLI agent in a new iTerm2 window with tmux in the current working directory.

## Your Mission

When the user runs `/codex`, execute:

```bash
CURRENT_DIR=$(pwd)
SESSION_NAME="codex-$(basename "${CURRENT_DIR}")"

# Kill existing session if any
tmux kill-session -t "${SESSION_NAME}" 2>/dev/null || true

# Create new tmux session
tmux new-session -d -s "${SESSION_NAME}" -c "${CURRENT_DIR}"
tmux send-keys -t "${SESSION_NAME}" "codex" Enter

# Open iTerm and attach
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

## Output Format

```
Opened Codex agent in tmux session '{SESSION_NAME}'.
```
