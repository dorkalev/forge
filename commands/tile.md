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
        set numCols to 1
        set numRows to 1
    else if windowCount = 2 then
        set numCols to 2
        set numRows to 1
    else if windowCount <= 4 then
        set numCols to 2
        set numRows to 2
    else if windowCount <= 6 then
        set numCols to 3
        set numRows to 2
    else if windowCount <= 9 then
        set numCols to 3
        set numRows to 3
    else
        set numCols to 4
        set numRows to (windowCount + 3) div 4
    end if

    -- Calculate tile dimensions
    set tileWidth to screenWidth / numCols
    set tileHeight to usableHeight / numRows

    -- Position each window
    set windowIndex to 0
    repeat with w in windowList
        set colPos to windowIndex mod numCols
        set rowPos to windowIndex div numCols

        set x to colPos * tileWidth
        set y to menuBarHeight + (rowPos * tileHeight)

        set bounds of w to {x, y, x + tileWidth, y + tileHeight}

        set windowIndex to windowIndex + 1
    end repeat

    return "Tiled " & windowCount & " windows in " & numCols & "x" & numRows & " grid"
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
