---
description: Tile all iTerm windows equally on screen
---

# /tile - Tile Tmux Sessions in iTerm Panes

You are an automation assistant that helps developers organize their terminal sessions.

## Your Mission

When the user runs `/tile`, consolidate all tmux sessions into a single iTerm window with split panes.

### Step 1: Get Tmux Sessions

```bash
tmux list-sessions -F "#{session_name}" 2>/dev/null
```

If no sessions exist, output:
```
No tmux sessions found.
```
And exit.

### Step 2: Show Current State

Display what will happen:

```
Found N tmux sessions:
  - session1
  - session2
  - session3

This will create a single iTerm window with N panes, each attached to a session.
```

### Step 3: Create Tiled Window

Run this script, substituting the session names:

```bash
# Get all tmux sessions
SESSIONS=($(tmux list-sessions -F "#{session_name}" 2>/dev/null))
SESSION_COUNT=${#SESSIONS[@]}

if [ "$SESSION_COUNT" -eq 0 ]; then
    echo "No tmux sessions found."
    exit 0
fi

# Build the AppleScript
osascript << EOF
tell application "iTerm"
    activate

    -- Create new window with first session
    set newWindow to (create window with default profile)
    tell current session of newWindow
        write text "tmux attach -t ${SESSIONS[0]}"
    end tell

    set sessionIndex to 1
    set totalSessions to $SESSION_COUNT

    -- Calculate grid: for 2 = 2x1, for 3-4 = 2x2, for 5-6 = 3x2, etc.
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
            -- First, create all columns by splitting vertically
            repeat (numCols - 1) times
                tell current session
                    split vertically with default profile
                end tell
            end repeat

            -- Now split each column horizontally to create rows
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

            -- Refresh sessions list after all splits
            set allSessions to sessions
            set sessionCount to count of allSessions

            -- Attach each pane to a tmux session
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

### Step 4: Report Result

After execution, output:

```
Tiled {N} tmux sessions into iTerm panes:
  - session1 (top-left)
  - session2 (top-right)
  - session3 (bottom-left)
  - session4 (bottom-right)
```

## Grid Layout Reference

| Sessions | Layout |
|----------|--------|
| 1 | Full window |
| 2 | Side by side (2 columns) |
| 3-4 | 2x2 grid |
| 5-6 | 3x2 grid |
| 7-9 | 3x3 grid |
| 10+ | 4xN grid |

## Error Handling

- If tmux is not installed: `tmux is not installed. Install with: brew install tmux`
- If no sessions exist: `No tmux sessions found. Start some with: tmux new -s <name>`
- If iTerm is not running: Script will launch iTerm automatically

## Notes

- Old iTerm windows are NOT closed automatically (user may have unsaved work)
- Each pane attaches to its tmux session (can detach with Ctrl+B, D)
- Use Cmd+[ and Cmd+] to navigate between panes
- Use Cmd+Shift+Enter to maximize/restore a pane
