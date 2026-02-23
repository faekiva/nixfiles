#!/usr/bin/env bash
set -euo pipefail

ssh sachi 'cat > /tmp/deploy.sh' << 'EOF'
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
git clone git@github.com:faekiva/nixfiles.git .
echo "$1" > .hostname
direnv allow .
direnv exec . task deploy
EOF

ssh -tt sachi bash /tmp/deploy.sh "$1"
