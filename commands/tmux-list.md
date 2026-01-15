---
description: List tmux sessions and attach to one in iTerm
---

# /tmux-list - List and Attach to Tmux Sessions

You are an automation assistant that helps developers manage their tmux sessions.

## Your Mission

When the user runs `/tmux-list`, execute this workflow:

### Step 1: List Tmux Sessions

Get all active tmux sessions:

```bash
tmux list-sessions -F "#{session_name}|#{session_windows}|#{session_attached}|#{session_created}" 2>/dev/null
```

If no sessions exist, output:
```
No tmux sessions found.
```
And exit.

### Step 2: Display Sessions

Parse the output and display as a formatted table:

```
## Active Tmux Sessions

| # | Session Name | Windows | Attached | Created |
|---|--------------|---------|----------|---------|
| 1 | ENG-123 | 2 | No | 2024-01-15 10:30 |
| 2 | ENG-456 | 1 | Yes | 2024-01-15 09:15 |
| 3 | main-dev | 3 | No | 2024-01-14 16:00 |
...
```

Format the `session_created` timestamp to be human-readable (convert from Unix timestamp).

### Step 3: Get User Selection

Use AskUserQuestion to let the user pick a session:
- Header: "Session"
- Question: "Which tmux session do you want to attach to?"
- Options: List up to 4 sessions by name (the most recent ones)
- If more than 4 sessions exist, the user can use "Other" to type the session name

**Important**: Even if there are more than 4 sessions, show ALL of them in the table above. The AskUserQuestion options are just shortcuts for the most common choices.

### Step 4: Open iTerm and Attach

Once the user selects a session, open iTerm and attach:

```bash
SESSION_NAME="<selected session>"

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

After attaching:

```
Opened iTerm and attached to tmux session: {SESSION_NAME}
```

## Error Handling

- If tmux is not installed: `tmux is not installed. Install with: brew install tmux`
- If no sessions exist: `No tmux sessions found.`
- If selected session doesn't exist: `Session "{name}" not found. Run /tmux-list again to see current sessions.`
- If iTerm is not installed: `iTerm is not installed. Please install iTerm2 from https://iterm2.com/`
