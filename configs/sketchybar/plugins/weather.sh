#!/bin/bash

# Fetch weather from wttr.in (no API key needed)
# Format: condition icon + temperature
WEATHER=$(curl -s "wttr.in/?format=%c%t" 2>/dev/null | sed 's/+//')

if [ -n "$WEATHER" ] && [ "$WEATHER" != "Unknown location" ]; then
  sketchybar --set "$NAME" label="$WEATHER"
else
  sketchybar --set "$NAME" label="--"
fi
