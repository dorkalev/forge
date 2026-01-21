---
description: Open Gemini CLI agent in a new iTerm2/tmux session
---

# /gemini - Open Gemini Agent

Opens Gemini CLI agent in a new iTerm2 window with tmux in the current working directory.

## Your Mission

When the user runs `/gemini`, execute:

```bash
CURRENT_DIR=$(pwd)
SESSION_NAME="gemini-$(basename "${CURRENT_DIR}")"

# Kill existing session if any
tmux kill-session -t "${SESSION_NAME}" 2>/dev/null || true

# Create new tmux session
tmux new-session -d -s "${SESSION_NAME}" -c "${CURRENT_DIR}"
tmux send-keys -t "${SESSION_NAME}" "gemini" Enter

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
Opened Gemini agent in tmux session '{SESSION_NAME}'.
```
