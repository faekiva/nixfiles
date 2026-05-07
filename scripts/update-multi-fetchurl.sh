#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: update-multi-fetchurl.sh <nix-file> <version>" >&2
  echo "  Updates the 'version = \"...\"' line, then for every url/hash pair" >&2
  echo "  substitutes \${version} in the url template, prefetches, and replaces" >&2
  echo "  the following hash line." >&2
  exit 1
}

[[ $# -eq 2 ]] || usage

NIX_FILE="$1"
VERSION="$2"

[[ -f "$NIX_FILE" ]] || { echo "error: $NIX_FILE not found" >&2; exit 1; }

perl -pi -e "s|version = \"[^\"]*\"|version = \"${VERSION}\"|" "$NIX_FILE"

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

PENDING_HASH=""
while IFS= read -r line; do
  if [[ -n "$PENDING_HASH" && "$line" == *"hash = \""* ]]; then
    line=$(printf '%s' "$line" | perl -pe "s|hash = \"[^\"]*\"|hash = \"$PENDING_HASH\"|")
    PENDING_HASH=""
  elif [[ "$line" =~ url[[:space:]]*=[[:space:]]*\"([^\"]*)\" ]]; then
    URL_TEMPLATE="${BASH_REMATCH[1]}"
    EVAL_URL="${URL_TEMPLATE//\$\{version\}/$VERSION}"
    printf "Fetching %s\n" "$EVAL_URL" >&2
    RAW=$(nix-prefetch-url --type sha256 "$EVAL_URL" 2>/dev/null)
    PENDING_HASH=$(nix hash to-sri --type sha256 "$RAW")
  fi
  printf '%s\n' "$line" >> "$TMPFILE"
done < "$NIX_FILE"

mv "$TMPFILE" "$NIX_FILE"

printf "Updated %s to version %s\n" "$NIX_FILE" "$VERSION"
