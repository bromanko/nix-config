#!/usr/bin/env bash
set -euo pipefail

# Bootstrap a Hetzner server from Debian -> NixOS using nixos-infect.
#
# Usage:
#   scripts/hetzner/bootstrap-nixos.sh <server-ip>
#
# Optional overrides:
#   NIX_CHANNEL=nixos-25.11 PROVIDER=hetznercloud scripts/hetzner/bootstrap-nixos.sh <ip>

SERVER_IP="${1:-}"
NIX_CHANNEL="${NIX_CHANNEL:-nixos-25.11}"
PROVIDER="${PROVIDER:-hetznercloud}"

if [[ -z "$SERVER_IP" ]]; then
  echo "Usage: $0 <server-ip>" >&2
  exit 1
fi

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $1" >&2
    exit 1
  fi
}

require ssh
require ssh-keygen
require grep

if ssh root@"$SERVER_IP" 'grep -q "NixOS" /etc/os-release'; then
  echo "Server already runs NixOS; skipping bootstrap."
  ssh root@"$SERVER_IP" 'grep ^PRETTY_NAME= /etc/os-release'
  exit 0
fi

echo "Running nixos-infect on $SERVER_IP ..."
set +e
ssh root@"$SERVER_IP" "
  rm -f /tmp/nixos-infect.*.swp
  curl -L https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect \
    | PROVIDER=$PROVIDER NIX_CHANNEL=$NIX_CHANNEL NO_SWAP=1 bootFs=/boot bash
"
infect_status=$?
set -e

# Reboot / SSH disconnect is expected during infect.
if [[ $infect_status -ne 0 ]]; then
  echo "nixos-infect returned non-zero (often expected during reboot). Continuing with readiness checks..."
fi

echo "Refreshing known_hosts entry for $SERVER_IP ..."
ssh-keygen -R "$SERVER_IP" >/dev/null 2>&1 || true

echo "Waiting for NixOS SSH to come back ..."
until ssh -o StrictHostKeyChecking=accept-new root@"$SERVER_IP" 'grep -q "NixOS" /etc/os-release'; do
  sleep 5
done

echo "NixOS is up:"
ssh root@"$SERVER_IP" 'grep ^PRETTY_NAME= /etc/os-release'

echo
echo "Disk/FS layout (use to confirm fileSystems UUIDs in host config):"
ssh root@"$SERVER_IP" 'lsblk -f'
