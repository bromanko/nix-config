#!/bin/bash

# Highlight focused workspace, dim empty ones, normal for occupied

# Detect system appearance
APPEARANCE=$(defaults read -g AppleInterfaceStyle 2>/dev/null)

if [ "$APPEARANCE" = "Dark" ]; then
  NORMAL_COLOR="0xffcdd6f4"
  DIMMED_COLOR="0x80cdd6f4"
else
  NORMAL_COLOR="0xff1e1e2e"
  DIMMED_COLOR="0x801e1e2e"
fi

# Focused workspace colors (light text on dark bg works in both modes)
FOCUSED_COLOR="0xffffffff"
FOCUSED_BG="0x503d3c53"

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
    # Focused workspace - pill with light text
    sketchybar --set "space.$WORKSPACE" \
      icon.color="$FOCUSED_COLOR" \
      icon.padding_left=8 \
      icon.padding_right=8 \
      background.color="$FOCUSED_BG" \
      background.corner_radius=8 \
      background.height=20 \
      background.drawing=on
  elif [ "$WINDOWS" -gt 0 ]; then
    # Has windows - normal
    sketchybar --set "space.$WORKSPACE" \
      icon.color="$NORMAL_COLOR" \
      icon.padding_left=8 \
      icon.padding_right=8 \
      background.drawing=off
  else
    # Empty - dimmed
    sketchybar --set "space.$WORKSPACE" \
      icon.color="$DIMMED_COLOR" \
      icon.padding_left=8 \
      icon.padding_right=8 \
      background.drawing=off
  fi
done
