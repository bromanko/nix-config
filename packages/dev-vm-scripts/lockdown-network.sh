#!/usr/bin/env bash
set -euo pipefail

# lockdown-network: Enable UFW firewall and dnsmasq DNS whitelist

usage() {
  cat <<EOF
Usage: lockdown-network

Enable network security lockdown:
- UFW firewall with deny-by-default outbound policy
- dnsmasq DNS whitelist (only GitHub and Nix domains)

This script must be run with sudo.
EOF
  exit 1
}

# If not running as root, re-exec with sudo using full path
if [ "$EUID" -ne 0 ]; then
  SCRIPT_PATH="$(readlink -f "$0")"
  echo "Re-executing with sudo: $SCRIPT_PATH"
  exec sudo "$SCRIPT_PATH" "$@"
fi

echo "=== Network Lockdown ==="
echo ""
echo "This will:"
echo "  1. Install and configure dnsmasq with DNS whitelist"
echo "  2. Enable UFW firewall with deny-by-default policy"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo ""
echo "Step 1: Installing packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y ufw dnsmasq

echo ""
echo "Step 2: Configuring dnsmasq with DNS whitelist..."

# Backup existing config if not already backed up
if [ -f /etc/dnsmasq.conf ] && [ ! -f /etc/dnsmasq.conf.pre-lockdown ]; then
  cp /etc/dnsmasq.conf /etc/dnsmasq.conf.pre-lockdown
fi

# Configure dnsmasq with whitelist-only DNS
cat > /etc/dnsmasq.conf <<'EOF'
# Listen on localhost only
listen-address=127.0.0.1
bind-interfaces

# Do not read /etc/resolv.conf or /etc/hosts
no-resolv
no-hosts

# Default: return NXDOMAIN for everything (block all)
address=/#/

# Whitelist: GitHub domains
server=/github.com/8.8.8.8
server=/githubusercontent.com/8.8.8.8
server=/github.io/8.8.8.8
server=/githubassets.com/8.8.8.8

# Whitelist: Nix/Nixpkgs infrastructure
server=/nixos.org/8.8.8.8
server=/cache.nixos.org/8.8.8.8

# Cache settings
cache-size=1000
EOF

# Configure system to use dnsmasq for DNS
systemctl enable dnsmasq
systemctl restart dnsmasq

# Disable systemd-resolved and point to localhost DNS
systemctl disable systemd-resolved || true
systemctl stop systemd-resolved || true
rm -f /etc/resolv.conf
echo "nameserver 127.0.0.1" > /etc/resolv.conf
chattr +i /etc/resolv.conf  # Make immutable

echo "dnsmasq configured with DNS whitelist"

echo ""
echo "Step 3: Configuring UFW firewall..."

# Reset to clean state
ufw --force reset

# Default policies: deny all traffic
ufw default deny outgoing
ufw default deny incoming

# Allow all traffic on loopback interface
ufw allow out on lo
ufw allow in on lo

# Allow incoming SSH from Lima host
ufw allow in from any to any port 22 proto tcp comment 'SSH from Lima host'

# Allow outbound SSH (for git operations and agent forwarding)
ufw allow out proto tcp to any port 22 comment 'SSH for git and agent forwarding'

# Allow DNS queries to localhost
ufw allow out to 127.0.0.1 proto udp port 53 comment 'DNS to localhost'

# Allow outbound DNS from VM to upstream resolvers (so dnsmasq can query whitelisted domains)
ufw allow out proto udp to any port 53 comment 'DNS to upstream resolvers'

# Allow HTTP/HTTPS (DNS whitelist controls which domains can be resolved)
ufw allow out proto tcp to any port 80 comment 'HTTP for package managers/etc'
ufw allow out proto tcp to any port 443 comment 'HTTPS for git/nix/etc'

# Enable firewall
ufw --force enable

echo ""
echo "=== Network Lockdown Complete ==="
echo ""
echo "UFW Status:"
ufw status verbose
echo ""
echo "DNS Whitelist:"
echo "  - github.com, githubusercontent.com, github.io, githubassets.com"
echo "  - nixos.org, cache.nixos.org"
echo ""
echo "Use 'allowlist-domain <domain>' to add more domains to the whitelist"
