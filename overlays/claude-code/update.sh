#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl gitMinimal jq coreutils
# shellcheck shell=bash

set -euo pipefail

base_url="https://downloads.claude.ai/claude-code-releases"
repo_root="$(git rev-parse --show-toplevel)"
package_dir="$repo_root/overlays/claude-code"
manifest_file="$package_dir/manifest.zst.json"
temp_dir="$(mktemp -d)"
manifest_temp="$temp_dir/manifest.zst.json"
trap 'rm -f "$manifest_temp"; rmdir "$temp_dir"' EXIT

old_version="$(jq --exit-status --raw-output '
  .version
  | select(type == "string" and test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))
' "$manifest_file")"

version="${1:-$(curl --silent --show-error --fail --location \
  "$base_url/latest")}"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: invalid version: $version" >&2
  exit 1
fi

curl --silent --show-error --fail --location \
  "$base_url/$version/manifest.zst.json" \
  --output "$manifest_temp"

expected_platforms='[
  "darwin-arm64",
  "darwin-x64",
  "linux-arm64",
  "linux-x64",
  "linux-arm64-musl",
  "linux-x64-musl",
  "win32-x64",
  "win32-arm64"
]'

if ! jq --exit-status \
  --arg version "$version" \
  --argjson expected "$expected_platforms" '
    . as $manifest
    | .version == $version
      and (.platforms | type == "object")
      and all(
        $expected[];
        . as $platform
        | $manifest.platforms[$platform]
        | type == "object"
          and (.binary | type == "string" and endswith(".zst"))
          and (.checksum | type == "string" and test("^[0-9a-f]{64}$"))
          and (.size | type == "number" and . > 0)
      )
  ' "$manifest_temp" >/dev/null; then
  echo "error: manifest for $version is incomplete or invalid" >&2
  exit 1
fi

if cmp --silent "$manifest_temp" "$manifest_file"; then
  echo "Claude Code manifest is already pinned to $old_version."
  exit 0
fi

mv "$manifest_temp" "$manifest_file"
git -C "$repo_root" commit --only \
  --message "claude-code: $old_version -> $version" \
  --message "Changelog: https://github.com/anthropics/claude-code/blob/v$version/CHANGELOG.md" \
  -- overlays/claude-code/manifest.zst.json
