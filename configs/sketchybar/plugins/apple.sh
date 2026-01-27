#!/bin/bash

# Show highlight (macOS-style selection - blueish pill)
sketchybar --set apple background.color=0x40a0c4e8

# Open Apple menu when clicked
osascript -e 'tell application "System Events" to tell process "Finder" to click menu bar item "Apple" of menu bar 1'

# Remove highlight after delay
sleep 0.3
sketchybar --set apple background.color=0x00000000
