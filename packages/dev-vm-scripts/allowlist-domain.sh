#!/usr/bin/env bash
set -euo pipefail

# allowlist-domain: Add a domain to the dnsmasq whitelist

DOMAIN="${1:-}"
DNSMASQ_CONF="/etc/dnsmasq.conf"
DNS_SERVER="8.8.8.8"

usage() {
  cat <<EOF
Usage: allowlist-domain <domain>

Add a domain to the dnsmasq DNS whitelist and restart dnsmasq.

Examples:
  allowlist-domain example.com
  allowlist-domain api.service.com

The domain will be added to $DNSMASQ_CONF as:
  server=/<domain>/$DNS_SERVER

This allows DNS resolution for the specified domain and all its subdomains.
EOF
  exit 1
}

if [ -z "$DOMAIN" ]; then
  echo "Error: Domain argument required" >&2
  echo "" >&2
  usage
fi

# Validate domain format (basic check)
if ! echo "$DOMAIN" | grep -qE '^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$'; then
  echo "Error: Invalid domain format: $DOMAIN" >&2
  exit 1
fi

# Check if dnsmasq.conf exists
if [ ! -f "$DNSMASQ_CONF" ]; then
  echo "Error: $DNSMASQ_CONF not found" >&2
  echo "Is dnsmasq installed and configured?" >&2
  exit 1
fi

# Check if domain is already allowlisted
if grep -q "server=/$DOMAIN/$DNS_SERVER" "$DNSMASQ_CONF"; then
  echo "Domain $DOMAIN is already allowlisted in $DNSMASQ_CONF"
  exit 0
fi

# Add domain to whitelist
echo "Adding $DOMAIN to DNS whitelist..."

# Find the line with "# Cache settings" and insert before it
# This keeps the whitelist entries grouped together
if grep -q "# Cache settings" "$DNSMASQ_CONF"; then
  # Insert before "# Cache settings"
  sudo sed -i "/# Cache settings/i server=/$DOMAIN/$DNS_SERVER" "$DNSMASQ_CONF"
else
  # If no "Cache settings" marker, append to end
  echo "server=/$DOMAIN/$DNS_SERVER" | sudo tee -a "$DNSMASQ_CONF" > /dev/null
fi

echo "Domain $DOMAIN added to whitelist"

# Restart dnsmasq
echo "Restarting dnsmasq..."
sudo systemctl restart dnsmasq

echo "Done! $DOMAIN is now resolvable."
echo ""
echo "Test with: dig $DOMAIN"
