#!/bin/bash

# Detect system appearance (returns "Dark" if dark mode, empty if light mode)
APPEARANCE=$(defaults read -g AppleInterfaceStyle 2>/dev/null)

if [ "$APPEARANCE" = "Dark" ]; then
  # Dark mode colors
  BAR_COLOR="0x651e1e2e"
  ICON_COLOR="0xffcdd6f4"
  LABEL_COLOR="0xffcdd6f4"
else
  # Light mode colors
  BAR_COLOR="0x65e6e9ef"
  ICON_COLOR="0xff1e1e2e"
  LABEL_COLOR="0xff1e1e2e"
fi

# Update bar
sketchybar --bar color="$BAR_COLOR"

# Update all items explicitly
ITEMS=(
  apple
  space.1 space.2 space.3 space.4 space.5 space.6 space.7 space.8 space.9 space.10
  clock weather memory cpu tailscale
)

# Alias items need alias.color instead of icon.color
ALIAS_ITEMS=(
  "Control Center,Battery"
  "Control Center,WiFi"
)

for item in "${ITEMS[@]}"; do
  sketchybar --set "$item" icon.color="$ICON_COLOR" label.color="$LABEL_COLOR" 2>/dev/null
done

for item in "${ALIAS_ITEMS[@]}"; do
  sketchybar --set "$item" alias.color="$ICON_COLOR" 2>/dev/null
done
