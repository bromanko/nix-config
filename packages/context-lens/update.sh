#!/usr/bin/env bash
# Update context-lens to the latest npm version.
# Usage: ./update.sh
set -euo pipefail

LATEST=$(npm view context-lens version 2>/dev/null)
echo "Latest context-lens version: $LATEST"

CURRENT=$(grep 'version = ' default.nix | head -1 | sed 's/.*"\(.*\)".*/\1/')
echo "Current version: $CURRENT"

if [ "$LATEST" = "$CURRENT" ]; then
  echo "Already up to date."
  exit 0
fi

echo "Updating to $LATEST..."
echo ""
echo "You'll need to:"
echo "  1. Update version in default.nix to $LATEST"
echo "  2. Update src hash (nix-prefetch-url --unpack https://registry.npmjs.org/context-lens/-/context-lens-${LATEST}.tgz)"
echo "  3. Check if dependency versions changed (npm view context-lens@${LATEST} dependencies --json)"
echo "  4. Update dependency hashes if needed"
