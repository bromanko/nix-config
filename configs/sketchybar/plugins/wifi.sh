#!/bin/bash

SSID=$(networksetup -getairportnetwork en0 2>/dev/null | sed 's/Current Wi-Fi Network: //')

if [ -n "$SSID" ] && [ "$SSID" != "You are not associated with an AirPort network." ]; then
  ICON="􀙇"
  LABEL="$SSID"
else
  ICON="􀙈"
  LABEL="Disconnected"
fi

sketchybar --set "$NAME" icon="$ICON" label="$LABEL"
