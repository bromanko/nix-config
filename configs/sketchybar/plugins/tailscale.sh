#!/bin/bash

STATUS=$(/Applications/Tailscale.app/Contents/MacOS/Tailscale status --json 2>/dev/null)

if [ -z "$STATUS" ]; then
  ICON="󰖂"
  LABEL="Off"
  COLOR="0x80ffffff"
elif echo "$STATUS" | grep -q '"BackendState":"Running"'; then
  ICON="󰖂"
  LABEL="On"
  COLOR="0xff89b4fa"
else
  ICON="󰖂"
  LABEL="Off"
  COLOR="0x80ffffff"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$LABEL"
