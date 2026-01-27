#!/bin/bash

# Highlight focused workspace, dim empty ones, normal for occupied

# If called with argument, update just that workspace
# If called via event, update all workspaces
if [ -n "$1" ]; then
  WORKSPACES="$1"
else
  WORKSPACES="1 2 3 4 5 6 7 8 9 10"
fi

FOCUSED=$(aerospace list-workspaces --focused 2>/dev/null)

for WORKSPACE in $WORKSPACES; do
  # Check if workspace has windows
  WINDOWS=$(aerospace list-windows --workspace "$WORKSPACE" 2>/dev/null | wc -l | tr -d ' ')

  if [ "$WORKSPACE" = "$FOCUSED" ]; then
    # Focused workspace - bright
    sketchybar --set "space.$WORKSPACE" \
      icon.color=0xfffab387 \
      background.color=0x40fab387
  elif [ "$WINDOWS" -gt 0 ]; then
    # Has windows - normal
    sketchybar --set "space.$WORKSPACE" \
      icon.color=0xffffffff \
      background.color=0x00000000
  else
    # Empty - dimmed
    sketchybar --set "space.$WORKSPACE" \
      icon.color=0x80ffffff \
      background.color=0x00000000
  fi
done
