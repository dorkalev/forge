---
description: Open Codex CLI agent in a new iTerm2/tmux session
---
# /codex - Open Codex Agent

```bash
CURRENT_DIR=$(pwd)
SESSION_NAME="codex-$(basename "${CURRENT_DIR}")"
tmux kill-session -t "${SESSION_NAME}" 2>/dev/null || true

FOLDER_NAME=$(basename "${CURRENT_DIR}")
tmux new-session -d -s "${SESSION_NAME}" -c "${CURRENT_DIR}"
tmux set-option -t "${SESSION_NAME}" status-left "[${FOLDER_NAME}] "
tmux set-option -t "${SESSION_NAME}" status-left-length 50
tmux send-keys -t "${SESSION_NAME}" "codex" Enter

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
Report: `Opened Codex agent in tmux session '{SESSION_NAME}'.`
