#!/bin/bash

TAILSCALE="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
STATUS=$($TAILSCALE status --json 2>/dev/null)

# Check modifier keys for different actions
# MODIFIER is set by sketchybar: shift, ctrl, alt, cmd
if [ "$MODIFIER" = "cmd" ]; then
  # Cmd+click: Open admin console
  open "https://login.tailscale.com/admin/machines"
elif [ "$MODIFIER" = "shift" ]; then
  # Shift+click: Open Tailscale app
  open -a Tailscale
else
  # Regular click: Toggle connection
  if echo "$STATUS" | grep -q '"BackendState":"Running"'; then
    $TAILSCALE down
  else
    $TAILSCALE up
  fi
fi

# Update the indicator
sleep 1
sketchybar --trigger tailscale_update
