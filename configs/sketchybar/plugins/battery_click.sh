#!/bin/bash

# Show battery menu by clicking the menu bar item
osascript -e '
tell application "System Events"
    tell process "ControlCenter"
        click menu bar item "Battery" of menu bar 1
    end tell
end tell
'
