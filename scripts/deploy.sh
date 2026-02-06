#!/usr/bin/env bash

set -euo pipefail

cd ./config

if [[ "$(uname)" == "Darwin" ]]; then
    if command -v darwin-rebuild &>/dev/null; then
        sudo darwin-rebuild switch --flake ".#$NIXFILES_HOSTNAME"
    else
        # Extract nix-darwin branch from flake.nix (e.g., "nix-darwin-25.11" from the input URL)
        DARWIN_BRANCH=$(grep 'nix-darwin\.url' "./flake.nix" | sed -n 's/.*\/\(nix-darwin-[0-9.]*\)".*/\1/p')
        sudo nix run "github:nix-darwin/nix-darwin/${DARWIN_BRANCH}#darwin-rebuild" -- switch --flake ".#$NIXFILES_HOSTNAME"
    fi
else
    sudo nixos-rebuild switch --flake ".#$NIXFILES_HOSTNAME"
fi