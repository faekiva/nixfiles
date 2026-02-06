#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIX_FILE="$SCRIPT_DIR/cline-cli.nix"
LOCK_FILE="$SCRIPT_DIR/cline-cli-lock.json"

# 1. Fetch latest version metadata from npm
echo "Fetching latest cline version from npm..."
META=$(curl -sS https://registry.npmjs.org/cline/latest)
VERSION=$(echo "$META" | jq -r '.version')
TARBALL_URL=$(echo "$META" | jq -r '.dist.tarball')
INTEGRITY=$(echo "$META" | jq -r '.dist.integrity')

echo "  version:   $VERSION"
echo "  tarball:   $TARBALL_URL"
echo "  integrity: $INTEGRITY"

# 2. Download tarball, extract, generate package-lock.json
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Downloading tarball..."
curl -sS -L "$TARBALL_URL" -o "$WORK_DIR/cline.tgz"

echo "Extracting and generating lockfile..."
tar xzf "$WORK_DIR/cline.tgz" -C "$WORK_DIR"
(cd "$WORK_DIR/package" && npm install --package-lock-only --ignore-scripts 2>/dev/null)

# 3. Copy lockfile
cp "$WORK_DIR/package/package-lock.json" "$LOCK_FILE"
echo "Updated $LOCK_FILE"

# 4. Compute npmDepsHash using prefetch-npm-deps
echo "Computing npmDepsHash (this may take a moment)..."
NPM_DEPS_HASH=$(prefetch-npm-deps "$LOCK_FILE" 2>/dev/null)
echo "  npmDepsHash: $NPM_DEPS_HASH"

# 5. Update cline-cli.nix in-place
sed -i '' "s|version = \".*\";|version = \"$VERSION\";|" "$NIX_FILE"
sed -i '' "s|url = \"https://registry.npmjs.org/cline/-/cline-.*\.tgz\";|url = \"$TARBALL_URL\";|" "$NIX_FILE"
sed -i '' "s|hash = \".*\";|hash = \"$INTEGRITY\";|" "$NIX_FILE"
sed -i '' "s|npmDepsHash = \".*\";|npmDepsHash = \"$NPM_DEPS_HASH\";|" "$NIX_FILE"

echo "Updated $NIX_FILE"
echo "Done! cline updated to $VERSION"
