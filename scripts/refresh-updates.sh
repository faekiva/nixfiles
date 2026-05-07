#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/updates.json"
LOCK="$REPO_ROOT/updates.lock"

[[ -f "$LOCK" ]] || echo '{}' > "$LOCK"

TMP=$(mktemp)
cp "$LOCK" "$TMP"
trap 'rm -f "$TMP" "$TMP.new"' EXIT

while read -r pkg; do
  name=$(jq -r '.name' <<<"$pkg")
  type=$(jq -r '.type' <<<"$pkg")
  case "$type" in
    github-release)
      repo=$(jq -r '.repo' <<<"$pkg")
      version=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name | sub("^v"; "")')
      ;;
    go-stable)
      version=$(curl -fsSL 'https://go.dev/dl/?mode=json' | jq -r '.[0].version')
      ;;
    *)
      echo "unknown type: $type" >&2
      exit 1
      ;;
  esac

  prev=$(jq -r --arg name "$name" '.[$name] // ""' "$TMP")
  if [[ "$prev" != "$version" ]]; then
    echo "$name: $prev -> $version"
  else
    echo "$name: $version (unchanged)"
  fi

  jq --arg name "$name" --arg version "$version" \
    '. + {($name): $version}' "$TMP" > "$TMP.new"
  mv "$TMP.new" "$TMP"
done < <(jq -c '.packages[]' "$MANIFEST")

jq -S '.' "$TMP" > "$LOCK"
