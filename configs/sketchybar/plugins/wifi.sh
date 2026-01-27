#!/bin/bash

SSID="$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | awk -F': ' '/^ *SSID/ {print $2}')"

if [ -n "$SSID" ]; then
  ICON="􀙇"
  LABEL="$SSID"
else
  ICON="􀙈"
  LABEL="Disconnected"
fi

sketchybar --set "$NAME" icon="$ICON" label="$LABEL"
