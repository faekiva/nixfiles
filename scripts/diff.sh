#!/usr/bin/env bash

set -euo pipefail

declare FLAKE_DERIVATION

if [[ "$(uname)" == "Darwin" ]]; then
    FLAKE_DERIVATION=$(nix build ./config#darwinConfigurations.$NIXFILES_HOSTNAME.system --print-out-paths --show-trace)
else
    FLAKE_DERIVATION=$(nix build ./config#nixosConfigurations.$NIXFILES_HOSTNAME.system --print-out-paths --show-trace)
fi

echo "FLAKE DERIVATION: $FLAKE_DERIVATION"

if [[ -e /run/current-system ]]; then
    nix-diff /run/current-system "$FLAKE_DERIVATION" --skip-already-compared
else
    echo "No current system found - this appears to be a fresh install."
    echo "New system will be: $FLAKE_DERIVATION"
fi
