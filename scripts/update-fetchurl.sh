#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: update-fetchurl.sh <nix-file> <url>" >&2
  exit 1
}

[[ $# -eq 2 ]] || usage

NIX_FILE="$1"
URL="$2"

[[ -f "$NIX_FILE" ]] || { echo "error: $NIX_FILE not found" >&2; exit 1; }

printf "Fetching %s...\n" "$URL"
RAW=$(nix-prefetch-url --type sha256 "$URL" 2>/dev/null)
SRI=$(nix hash convert --hash-algo sha256 --to sri "$RAW")

perl -pi -e "s|url = \"[^\"]*\"|url = \"$URL\"|" "$NIX_FILE"
perl -pi -e "s|hash = \"[^\"]*\"|hash = \"$SRI\"|" "$NIX_FILE"

printf "Updated %s\n  url  = \"%s\"\n  hash = \"%s\"\n" "$NIX_FILE" "$URL" "$SRI"
