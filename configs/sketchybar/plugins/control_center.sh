#!/bin/bash

# Open Control Center when clicked
osascript -e 'tell application "System Events" to tell process "ControlCenter" to click menu bar item "Control Center" of menu bar 1'
