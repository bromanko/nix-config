#!/usr/bin/env bash
set -eo pipefail

URL="https://nixos.org/nix/install"

[[ -n "$1" ]] && URL="$1"

# Nix
if command -v nix >/dev/null; then
    echo "nix is already installed on this system."
else
    [[ $(uname -s) = "Darwin" ]] && FLAG="--darwin-use-unencrypted-nix-store-volume"
    sh <(curl -L "$URL") $FLAG
fi

# Flakes
if nix flake >/dev/null 2>&1; then
    echo "nix Flakes is already installed on this system."
else
    nix-env -iA nixpkgs.nix
    if ! grep "experimental-features" <~/.config/nix/nix.conf >/dev/null; then
        mkdir -p ~/.config/nix
        touch ~/.config/nix/nix.conf
        echo "experimental-features = nix-command flakes" >>~/.config/nix/nix.conf
    fi
fi
