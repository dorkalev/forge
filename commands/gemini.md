---
description: Open Gemini CLI agent in a new iTerm2/tmux session
---

# /gemini - Open Gemini Agent

Opens Gemini CLI agent in a new iTerm2 window with tmux in the current working directory.

## Your Mission

When the user runs `/gemini`:

### Step 1: Confirm Paid Plan Access

Use AskUserQuestion to verify access:
- Header: "Gemini Access"
- Question: "Do you have a Gemini paid plan? (Admin needs to enable access per developer)"
- Options:
  - "Yes, I have access"
  - "No, I need access"

**If "No, I need access"**: Stop and output:
```
You need a Gemini paid plan to use the CLI. Please contact your admin to get access enabled for your account.
```

**If "Yes, I have access"**: Continue to Step 2.

### Step 2: Open Gemini

Execute:

```bash
CURRENT_DIR=$(pwd)
SESSION_NAME="gemini-$(basename "${CURRENT_DIR}")"

# Kill existing session if any
tmux kill-session -t "${SESSION_NAME}" 2>/dev/null || true

# Create new tmux session
FOLDER_NAME=$(basename "${CURRENT_DIR}")
tmux new-session -d -s "${SESSION_NAME}" -c "${CURRENT_DIR}"

# Configure status bar to show folder name
tmux set-option -t "${SESSION_NAME}" status-left "[${FOLDER_NAME}] "
tmux set-option -t "${SESSION_NAME}" status-left-length 50

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
