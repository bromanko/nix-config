#!/bin/bash

MEMORY=$(memory_pressure | grep "System-wide memory free percentage:" | awk '{print 100-$5}' | cut -d. -f1)

if [ "$MEMORY" -ge 80 ]; then
  ICON="􀫦"
elif [ "$MEMORY" -ge 50 ]; then
  ICON="􀫥"
else
  ICON="􀧓"
fi

sketchybar --set "$NAME" icon="$ICON" label="${MEMORY}%"
