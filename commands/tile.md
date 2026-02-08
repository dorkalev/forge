---
description: Tile all iTerm windows equally on screen
---
# /tile - Tile Tmux Sessions in iTerm Panes

Consolidate all tmux sessions into a single iTerm window with split panes.

### Step 1: Get Sessions
```bash
tmux list-sessions -F "#{session_name}" 2>/dev/null
```
If none: `No tmux sessions found.` and exit.

### Step 2: Create Tiled Window
```bash
SESSIONS=($(tmux list-sessions -F "#{session_name}" 2>/dev/null))
SESSION_COUNT=${#SESSIONS[@]}

if [ "$SESSION_COUNT" -eq 0 ]; then
    echo "No tmux sessions found."
    exit 0
fi

osascript << EOF
tell application "iTerm"
    activate
    set newWindow to (create window with default profile)
    tell current session of newWindow
        write text "tmux attach -t ${SESSIONS[0]}"
    end tell

    set sessionIndex to 1
    set totalSessions to $SESSION_COUNT

    -- Grid: 1=1x1, 2=2x1, 3-4=2x2, 5-6=3x2, 7-9=3x3, 10+=4xN
    if totalSessions = 1 then
        set numCols to 1
        set numRows to 1
    else if totalSessions = 2 then
        set numCols to 2
        set numRows to 1
    else if totalSessions ≤ 4 then
        set numCols to 2
        set numRows to 2
    else if totalSessions ≤ 6 then
        set numCols to 3
        set numRows to 2
    else if totalSessions ≤ 9 then
        set numCols to 3
        set numRows to 3
    else
        set numCols to 4
        set numRows to (totalSessions + 3) div 4
    end if

    tell newWindow
        tell current tab
            repeat (numCols - 1) times
                tell current session
                    split vertically with default profile
                end tell
            end repeat

            set allSessions to sessions
            repeat with colIndex from 1 to numCols
                if numRows > 1 then
                    set targetSession to item colIndex of allSessions
                    tell targetSession
                        repeat (numRows - 1) times
                            split horizontally with default profile
                        end repeat
                    end tell
                end if
            end repeat

            set allSessions to sessions
            set sessionCount to count of allSessions
            set tmuxSessions to {$(printf '"%s", ' "${SESSIONS[@]}" | sed 's/, $//')}
            set tmuxCount to count of tmuxSessions

            repeat with i from 1 to sessionCount
                if i ≤ tmuxCount then
                    tell item i of allSessions
                        write text "tmux attach -t " & item i of tmuxSessions
                    end tell
                end if
            end repeat
        end tell
    end tell
    return "Created window with " & totalSessions & " panes"
end tell
EOF

echo "Tiled $SESSION_COUNT tmux sessions into iTerm panes"
```

Report which session is in which position. Old iTerm windows are NOT closed (user may have unsaved work). Navigate: Cmd+[/], Maximize: Cmd+Shift+Enter.

## Error Handling
- tmux not installed → `brew install tmux` | No sessions → report | iTerm not running → script launches it
