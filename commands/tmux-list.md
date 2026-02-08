---
description: List tmux sessions and attach to one in iTerm
---
# /tmux-list - List and Attach to Tmux Sessions

### Step 1: List Sessions
```bash
tmux list-sessions -F "#{session_name}|#{session_windows}|#{session_attached}|#{session_created}" 2>/dev/null
```
If none: `No tmux sessions found.` and exit.

### Step 2: Display
Format as table: `| # | Session Name | Windows | Attached | Created |`. Convert Unix timestamp to readable.

### Step 3: User Selection
AskUserQuestion — Header: "Session", Question: "Which tmux session to attach to?", Options: up to 4 most recent sessions. More than 4 → user can type via "Other". Show ALL in table regardless.

### Step 4: Open iTerm and Attach
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
Report: `Opened iTerm and attached to tmux session: {SESSION_NAME}`

## Error Handling
- tmux not installed → `brew install tmux` | No sessions → report
- Session not found → run /tmux-list again | iTerm not installed → suggest install
