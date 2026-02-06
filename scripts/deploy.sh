#!/usr/bin/env bash

if [[ "$(uname)" == "Darwin" ]]; then
    if command -v darwin-rebuild &>/dev/null; then
        sudo darwin-rebuild switch --flake ".#$NIXFILES_HOSTNAME"
    else
        STATE_VERSION=$(grep 'system\.stateVersion' "config/hosts/Darwin/$NIXFILES_HOSTNAME/configuration.nix" | sed 's/.*=\s*\([0-9]*\).*/\1/')
        sudo nix run "nix-darwin/nix-darwin-$STATE_VERSION#darwin-rebuild" -- switch --flake ".#$NIXFILES_HOSTNAME"
    fi
else
    sudo nixos-rebuild switch --flake "./config#$NIXFILES_HOSTNAME"
fi