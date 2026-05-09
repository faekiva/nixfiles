#!/usr/bin/env bash
set -euo pipefail

PROFILE="/nix/var/nix/profiles/system"

if [[ ! -e "$PROFILE" ]]; then
  echo "No system profile at $PROFILE" >&2
  exit 1
fi

current=$(readlink "$PROFILE" | sed -E 's/.*system-([0-9]+)-link/\1/')

generations=$(sudo nix-env --list-generations --profile "$PROFILE")

choice=$(echo "$generations" \
  | awk -v cur="$current" '{
      marker = ($1 == cur) ? " (current)" : ""
      print $0 marker
    }' \
  | awk '{ a[NR] = $0 } END { for (i = NR; i > 0; i--) print a[i] }' \
  | gum choose --header "Select generation to roll back to (current: $current)")

if [[ -z "$choice" ]]; then
  echo "No selection, aborting." >&2
  exit 1
fi

gen=$(awk '{print $1}' <<<"$choice")

if [[ "$gen" == "$current" ]]; then
  echo "Already on generation $gen, nothing to do."
  exit 0
fi

target="/nix/var/nix/profiles/system-${gen}-link"

if [[ ! -e "$target" ]]; then
  echo "Generation link missing: $target" >&2
  exit 1
fi

echo "Switching from generation $current to $gen..."

sudo nix-env --switch-generation "$gen" --profile "$PROFILE"

case "$(uname)" in
  Darwin)
    sudo "$target/activate"
    ;;
  Linux)
    sudo "$target/bin/switch-to-configuration" switch
    ;;
  *)
    echo "Unsupported OS: $(uname)" >&2
    exit 1
    ;;
esac

echo "Now on generation $gen."
