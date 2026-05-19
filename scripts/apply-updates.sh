#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/updates.json"
LOCK="$REPO_ROOT/updates.lock"

cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# Helper: build a skeleton nix file for a github-release binary
# ---------------------------------------------------------------------------
create_github_release_skeleton() {
  local nix_file="$1"
  local repo="$2"
  local version="$3"

  local pname="${repo#*/}"
  pname="${pname,,}"

  # Fetch asset names from the latest release
  local asset_names
  asset_names=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
    | jq -r '.assets[].name')

  # Detect darwin assets and split by arch
  local x64_asset="" arm64_asset=""
  while IFS= read -r asset; do
    local lower
    lower=$(echo "$asset" | tr '[:upper:]' '[:lower:]')
    # Only consider tarballs / tgz files
    [[ "$lower" != *.tgz && "$lower" != *.tar.gz ]] && continue
    # Must be macOS / darwin
    [[ "$lower" != *"macos"* && "$lower" != *"darwin"* && "$lower" != *"osx"* ]] && continue
    if [[ "$lower" == *"arm64"* || "$lower" == *"aarch64"* || "$lower" == *"m1"* ]]; then
      [[ -z "$arm64_asset" ]] && arm64_asset="$asset"
    elif [[ "$lower" == *"x86"* || "$lower" == *"amd64"* || "$lower" == *"x64"* || "$lower" == *"intel"* ]]; then
      [[ -z "$x64_asset" ]] && x64_asset="$asset"
    elif [[ -z "$x64_asset" ]]; then
      # Darwin asset without arch qualifier → assume x86_64
      x64_asset="$asset"
    fi
  done <<<"$asset_names"

  if [[ -z "$x64_asset" && -z "$arm64_asset" ]]; then
    echo "  ⚠  no darwin release assets found for ${repo}" >&2
    return 1
  fi

  # Guess binary name by stripping version suffix and extension from asset
  local bin_name
  bin_name="${arm64_asset:-$x64_asset}"
  bin_name="${bin_name%%-v[0-9]*}"   # strip -vVERSION
  bin_name="${bin_name%%_v[0-9]*}"   # strip _vVERSION
  bin_name="${bin_name%%.*}"          # strip extension

  mkdir -p "$(dirname "$nix_file")"

  {
    echo "{"
    echo "  lib,"
    echo "  stdenv,"
    echo "  fetchurl,"
    echo "}:"
    echo "let"
    echo "  version = \"PLACEHOLDER\";"
    echo "  assets = {"
    if [[ -n "$x64_asset" ]]; then
      local x64_asset_tmpl="${x64_asset//${version}/\${version}}"
      echo "    x86_64-darwin = {"
      echo "      url = \"https://github.com/${repo}/releases/download/v\${version}/${x64_asset_tmpl}\";"
      echo "      hash = \"\";"
      echo "    };"
    fi
    if [[ -n "$arm64_asset" ]]; then
      local arm64_asset_tmpl="${arm64_asset//${version}/\${version}}"
      echo "    aarch64-darwin = {"
      echo "      url = \"https://github.com/${repo}/releases/download/v\${version}/${arm64_asset_tmpl}\";"
      echo "      hash = \"\";"
      echo "    };"
    fi
    echo "  };"
    echo "  asset ="
    echo "    assets.\${stdenv.hostPlatform.system} or (throw \"unsupported system: \${stdenv.hostPlatform.system}\");"
    echo "in"
    echo "stdenv.mkDerivation {"
    echo "  pname = \"${pname}\";"
    echo "  inherit version;"
    echo ""
    echo "  src = fetchurl {"
    echo "    inherit (asset) url hash;"
    echo "  };"
    echo ""
    echo "  sourceRoot = \".\";"
    echo ""
    echo "  dontBuild = true;"
    echo ""
    echo "  installPhase = ''"
    echo "    runHook preInstall"
    echo ""
    echo "    mkdir -p \$out/bin"
    echo "    install -m755 ${bin_name} \$out/bin/${bin_name}"
    echo ""
    echo "    runHook postInstall"
    echo "  '';"
    echo ""
    echo "  meta = with lib; {"
    echo "    description = \"\";"
    echo "    homepage = \"https://github.com/${repo}\";"
    echo "    license = licenses.asl20;"
    echo "    platforms = ["
    [[ -n "$x64_asset" ]] && echo '      "x86_64-darwin"'
    [[ -n "$arm64_asset" ]] && echo '      "aarch64-darwin"'
    echo "    ];"
    echo "    mainProgram = \"${bin_name}\";"
    echo "  };"
    echo "}"
  } >"$nix_file"
}

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
while read -r pkg; do
  name=$(jq -r '.name' <<<"$pkg")
  type=$(jq -r '.type' <<<"$pkg")
  file=$(jq -r '.file' <<<"$pkg")
  if [[ -f "$LOCK" ]]; then
    version=$(jq -r --arg name "$name" '.[$name] // empty' "$LOCK")
  else
    version=""
  fi

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

  # --- File doesn't exist yet ---
  if [[ ! -f "$file" ]]; then
    case "$type" in
      github-release)
        if gum confirm "📦  Create skeleton nix file for $name ($version)?"; then
          repo=$(jq -r '.repo' <<<"$pkg")
          create_github_release_skeleton "$file" "$repo" "$version"
          echo "  ✓  Created $file (review description & installPhase if needed)"
        else
          echo "$name: skipping — create $file manually" >&2
          continue
        fi
        ;;
      *)
        echo "error: $file not found — create it first, then re-run" >&2
        exit 1
        ;;
    esac
  fi

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
