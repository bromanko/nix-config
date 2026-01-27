#!/bin/bash

CPU=$(ps -A -o %cpu | awk '{sum+=$1} END {printf "%.0f", sum}')

if [ "$CPU" -ge 80 ]; then
  ICON="􀧓"
elif [ "$CPU" -ge 50 ]; then
  ICON="􀫥"
else
  ICON="􀫦"
fi

sketchybar --set "$NAME" icon="$ICON" label="${CPU}%"
