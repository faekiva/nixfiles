#!/usr/bin/env bash

declare FLAKE_DERIVATION

if [ "$PROMPT_HOST" = 'batgirl' ]; then
    FLAKE_DERIVATION=$(nix build ./config#darwinConfigurations.batgirl.system --print-out-paths --show-trace)
elif [ "$(uname -n)" = 'sachi' ]; then
    FLAKE_DERIVATION=$(nix build ./config#nixosConfigurations.sachi.system --print-out-paths --show-trace)
else
    echo "couldn't identify machine"
    exit 1
fi

echo "FLAKE DERIVATION: $FLAKE_DERIVATION"

nix-diff /run/current-system "$FLAKE_DERIVATION" --skip-already-compared
