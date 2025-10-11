#!/bin/bash

# Helper script for managing Privoxy allowed domains
# This script allows you to easily add/remove domains from the allow list
# without needing to rebuild the Nix configuration

PRIVOXY_ACTION_FILE="/var/lib/privoxy/user.action"

usage() {
    echo "Usage: $0 {add|remove|list|edit|restart} [domain]"
    echo ""
    echo "Commands:"
    echo "  add DOMAIN     Add a domain to the allow list"
    echo "  remove DOMAIN  Remove a domain from the allow list"
    echo "  list          List all allowed domains"
    echo "  edit          Open the action file in an editor"
    echo "  restart       Restart the Privoxy service"
    echo ""
    echo "Examples:"
    echo "  $0 add github.com"
    echo "  $0 add .example.com    # Allow example.com and all subdomains"
    echo "  $0 remove github.com"
    echo "  $0 list"
    echo "  $0 restart"
}

add_domain() {
    local domain="$1"
    if [[ -z "$domain" ]]; then
        echo "Error: Domain not specified"
        usage
        exit 1
    fi

    # Add domain to the allow section
    if ! grep -q "^$domain$" "$PRIVOXY_ACTION_FILE" 2>/dev/null; then
        # Add the domain after the "Add your allowed domains below" comment
        sed -i "/# Add your allowed domains below/a\\
# Allow $domain\\
{ -block }\\
$domain" "$PRIVOXY_ACTION_FILE"
        echo "Added $domain to allow list"
        echo "Run '$0 restart' to apply changes"
    else
        echo "$domain is already in the allow list"
    fi
}

remove_domain() {
    local domain="$1"
    if [[ -z "$domain" ]]; then
        echo "Error: Domain not specified"
        usage
        exit 1
    fi

    # Remove domain and its comment
    if grep -q "^$domain$" "$PRIVOXY_ACTION_FILE" 2>/dev/null; then
        sed -i "/# Allow $domain/,+2d" "$PRIVOXY_ACTION_FILE"
        echo "Removed $domain from allow list"
        echo "Run '$0 restart' to apply changes"
    else
        echo "$domain not found in allow list"
    fi
}

list_domains() {
    echo "Currently allowed domains:"
    if [[ -f "$PRIVOXY_ACTION_FILE" ]]; then
        # Extract domains from the { -block } sections
        awk '/^{ -block }$/,/^[^#]/ {
            if ($0 ~ /^[^#{ ]/ && $0 !~ /^$/) {
                print "  " $0
            }
        }' "$PRIVOXY_ACTION_FILE" | grep -v "127.0.0.0\|10.0.0.0\|192.168.0.0\|172.16.0.0" || echo "  No domains configured"
    else
        echo "  Privoxy action file not found"
    fi
}

edit_config() {
    local editor="${EDITOR:-nano}"
    echo "Opening $PRIVOXY_ACTION_FILE in $editor"
    sudo "$editor" "$PRIVOXY_ACTION_FILE"
    echo "Remember to run '$0 restart' to apply changes"
}

restart_privoxy() {
    echo "Restarting Privoxy service..."
    sudo systemctl restart privoxy
    if sudo systemctl is-active --quiet privoxy; then
        echo "Privoxy restarted successfully"
    else
        echo "Error: Failed to restart Privoxy"
        sudo systemctl status privoxy
    fi
}

# Check if running as root for file modifications
check_permissions() {
    if [[ "$1" != "list" ]] && [[ $EUID -ne 0 ]] && [[ "$1" != "edit" ]]; then
        echo "Error: This command requires root privileges"
        echo "Please run with sudo: sudo $0 $*"
        exit 1
    fi
}

# Main script logic
case "${1:-}" in
    "add")
        check_permissions "$1"
        add_domain "$2"
        ;;
    "remove")
        check_permissions "$1"
        remove_domain "$2"
        ;;
    "list")
        list_domains
        ;;
    "edit")
        edit_config
        ;;
    "restart")
        restart_privoxy
        ;;
    *)
        usage
        exit 1
        ;;
esac