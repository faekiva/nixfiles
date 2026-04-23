#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

VERSION=$(curl -fsSL 'https://go.dev/dl/?mode=json' | jq -r '.[0].version')
URL="https://go.dev/dl/${VERSION}.src.tar.gz"

"$SCRIPT_DIR/update-fetchurl.sh" \
  "$REPO_ROOT/config/modules/hereafter/hm/go.nix" \
  "$URL"
