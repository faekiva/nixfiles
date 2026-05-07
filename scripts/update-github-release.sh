#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
  echo "usage: update-github-release.sh <nix-file> <owner/repo> [version]" >&2
  echo "  Fetches the latest release tag from GitHub (or uses [version])," >&2
  echo "  strips a leading 'v', then updates url/hash pairs in <nix-file>." >&2
  exit 1
}

[[ $# -ge 2 && $# -le 3 ]] || usage

NIX_FILE="$1"
REPO="$2"

if [[ $# -eq 3 ]]; then
  VERSION="$3"
else
  TAG=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | jq -r '.tag_name')
  VERSION="${TAG#v}"
fi

"$SCRIPT_DIR/update-multi-fetchurl.sh" "$NIX_FILE" "$VERSION"
