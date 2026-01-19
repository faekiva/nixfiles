#!/usr/bin/env bash

declare FLAKE_DERIVATION

if [ "$PROMPT_HOST" = 'batgirl' ]; then
    FLAKE_DERIVATION=$(nix build ./config#darwinConfigurations.batgirl.system --print-out-paths 2>/dev/null)
elif [ "$(uname -n)" = 'sachi' ]; then
    FLAKE_DERIVATION=$(nix build ./config#nixosConfigurations.sachi.system --print-out-paths 2>/dev/null)
fi

nix-diff /run/current-system "$FLAKE_DERIVATION" --skip-already-compared
