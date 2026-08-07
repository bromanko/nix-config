#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Clean Wrapped URL
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🔗
# @raycast.packageName Clipboard Tools
# @raycast.description Remove whitespace and line wraps from a copied URL

clipboard="$(pbpaste)"

if [[ -z "$clipboard" ]]; then
  echo "Clipboard is empty"
  exit 1
fi

cleaned="$(printf '%s' "$clipboard" | tr -d '[:space:]')"
printf '%s' "$cleaned" | pbcopy

echo "Cleaned URL copied"
