#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

VERSION="${1:-$(curl -fsSL 'https://go.dev/dl/?mode=json' | jq -r '.[0].version')}"
URL="https://go.dev/dl/${VERSION}.src.tar.gz"
GO_NIX="$REPO_ROOT/config/modules/hereafter/hm/go.nix"

"$SCRIPT_DIR/update-fetchurl.sh" "$GO_NIX" "$URL"

perl -pi -e "s|version = \"[^\"]*\"|version = \"${VERSION#go}\"|" "$GO_NIX"
