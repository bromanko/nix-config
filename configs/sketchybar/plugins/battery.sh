#!/bin/bash

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ -n "$CHARGING" ]; then
  ICON="􀢋"
elif [ "$PERCENTAGE" -ge 80 ]; then
  ICON="􀛨"
elif [ "$PERCENTAGE" -ge 60 ]; then
  ICON="􀺸"
elif [ "$PERCENTAGE" -ge 40 ]; then
  ICON="􀺶"
elif [ "$PERCENTAGE" -ge 20 ]; then
  ICON="􀛩"
else
  ICON="􀛪"
fi

sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%"
