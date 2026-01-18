---
description: Tile all iTerm windows equally on screen
---

# /tile - Tile iTerm Windows

You are an automation assistant that helps developers organize their terminal windows.

## Your Mission

When the user runs `/tile`, execute this AppleScript to tile all iTerm windows equally on the screen:

```bash
osascript << 'EOF'
tell application "iTerm"
    set windowList to windows
    set windowCount to count of windowList

    if windowCount = 0 then
        return "No iTerm windows to tile"
    end if

    -- Get screen dimensions (main screen)
    tell application "Finder"
        set screenBounds to bounds of window of desktop
        set screenWidth to item 3 of screenBounds
        set screenHeight to item 4 of screenBounds
    end tell

    -- Account for menu bar (roughly 25 pixels)
    set menuBarHeight to 25
    set usableHeight to screenHeight - menuBarHeight

    -- Calculate grid dimensions
    if windowCount = 1 then
        set cols to 1
        set rows to 1
    else if windowCount = 2 then
        set cols to 2
        set rows to 1
    else if windowCount <= 4 then
        set cols to 2
        set rows to 2
    else if windowCount <= 6 then
        set cols to 3
        set rows to 2
    else if windowCount <= 9 then
        set cols to 3
        set rows to 3
    else
        set cols to 4
        set rows to (windowCount + 3) div 4
    end if

    -- Calculate tile dimensions
    set tileWidth to screenWidth / cols
    set tileHeight to usableHeight / rows

    -- Position each window
    set windowIndex to 0
    repeat with w in windowList
        set col to windowIndex mod cols
        set row to windowIndex div cols

        set x to col * tileWidth
        set y to menuBarHeight + (row * tileHeight)

        set bounds of w to {x, y, x + tileWidth, y + tileHeight}

        set windowIndex to windowIndex + 1
    end repeat

    return "Tiled " & windowCount & " windows in " & cols & "x" & rows & " grid"
end tell
EOF
```

## Output Format

Report the result:

```
Tiled {N} iTerm windows in {cols}x{rows} grid
```

## Grid Layout Reference

| Windows | Layout |
|---------|--------|
| 1 | Full screen |
| 2 | Side by side (2x1) |
| 3-4 | 2x2 grid |
| 5-6 | 3x2 grid |
| 7-9 | 3x3 grid |
| 10+ | 4xN grid |

## Error Handling

- If iTerm is not running: `iTerm is not running. Open iTerm first.`
- If no windows exist: `No iTerm windows to tile.`
