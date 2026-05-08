#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

VERSION="${1:-$(curl -fsSL 'https://go.dev/dl/?mode=json' | jq -r '.[0].version')}"
GO_NIX="$REPO_ROOT/config/modules/hereafter/hm/go.nix"

"$SCRIPT_DIR/update-multi-fetchurl.sh" "$GO_NIX" "${VERSION#go}"
