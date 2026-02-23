#!/usr/bin/env bash
set -euo pipefail

# Apply a NixOS host flake config to a remote host.
#
# Usage:
#   scripts/hetzner/apply-host-config.sh <server-ip> [flake-host]
#
# Example:
#   scripts/hetzner/apply-host-config.sh 5.78.44.117 sleeper-service

SERVER_IP="${1:-}"
FLAKE_HOST="${2:-sleeper-service}"
BUILD_CORES="${BUILD_CORES:-1}"
MAX_JOBS="${MAX_JOBS:-1}"
INSTALL_BOOTLOADER="${INSTALL_BOOTLOADER:-0}"

if [[ -z "$SERVER_IP" ]]; then
  echo "Usage: $0 <server-ip> [flake-host]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

rebuild_args=(
  switch
  --no-reexec
  --use-substitutes
  --cores "$BUILD_CORES"
  --max-jobs "$MAX_JOBS"
  --flake "$REPO_ROOT#$FLAKE_HOST"
  --target-host "root@$SERVER_IP"
  --build-host "root@$SERVER_IP"
)

if [[ "$INSTALL_BOOTLOADER" == "1" ]]; then
  rebuild_args+=(--install-bootloader)
fi

# Run as the invoking user by default so SSH agent keys are available.
# Set APPLY_WITH_SUDO=1 if you explicitly want local sudo.
if [[ "${APPLY_WITH_SUDO:-0}" == "1" ]]; then
  exec sudo --preserve-env=SSH_AUTH_SOCK nixos-rebuild "${rebuild_args[@]}"
fi

exec nixos-rebuild "${rebuild_args[@]}"
