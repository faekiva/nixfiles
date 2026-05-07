#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/updates.json"
LOCK="$REPO_ROOT/updates.lock"

cd "$REPO_ROOT"

while read -r pkg; do
  name=$(jq -r '.name' <<<"$pkg")
  type=$(jq -r '.type' <<<"$pkg")
  file=$(jq -r '.file' <<<"$pkg")
  version=$(jq -r --arg name "$name" '.[$name] // empty' "$LOCK")

  if [[ -z "$version" ]]; then
    echo "$name: no lock entry, skipping (run refresh-updates.sh)" >&2
    continue
  fi

  case "$type" in
    github-release)
      pinned="$version"
      ;;
    go-stable)
      pinned="${version#go}"
      ;;
  esac

  if grep -qF "version = \"${pinned}\"" "$file"; then
    echo "$name: already at $version"
    continue
  fi

  echo "$name: applying $version"
  case "$type" in
    github-release)
      repo=$(jq -r '.repo' <<<"$pkg")
      "$SCRIPT_DIR/update-github-release.sh" "$file" "$repo" "$version"
      ;;
    go-stable)
      "$SCRIPT_DIR/update-go.sh" "$version"
      ;;
  esac
done < <(jq -c '.packages[]' "$MANIFEST")
