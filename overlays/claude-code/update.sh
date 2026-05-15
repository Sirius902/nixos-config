#!/usr/bin/env nix
#!nix shell --ignore-environment --keep HOME --keep SSH_AUTH_SOCK nixpkgs#cacert nixpkgs#coreutils nixpkgs#gnused nixpkgs#curl nixpkgs#bash nixpkgs#jq nixpkgs#git nixpkgs#openssh --command bash

set -euo pipefail

cd "$(git rev-parse --show-toplevel)/overlays/claude-code"

BASE_URL="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"
CHANGELOG="https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md"

OLD_VERSION=$(sed -n 's/.*version = "\(.*\)".*/\1/p' default.nix)
VERSION="${1:-$(curl -fsSL "$BASE_URL/latest")}"

if [ "$OLD_VERSION" = "$VERSION" ]; then
  echo "claude-code is already up-to-date at $VERSION"
  exit 0
fi

MANIFEST=$(curl -fsSL "$BASE_URL/$VERSION/manifest.json")

sed -i "s/version = \".*\"/version = \"$VERSION\"/" default.nix

for platform in darwin-arm64 darwin-x64 linux-arm64 linux-x64; do
  checksum=$(echo "$MANIFEST" | jq -r ".platforms.\"$platform\".checksum")
  sed -i "s/\"$platform\" = \".*\"/\"$platform\" = \"$checksum\"/" default.nix
done

git add default.nix
git commit -m "claude-code: $OLD_VERSION -> $VERSION" -m "Changelog: $CHANGELOG"
