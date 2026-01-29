#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update

set -euo pipefail
set -x

version=$(npm view ccstatusline version)

# Update version and hashes
echo "$version"
