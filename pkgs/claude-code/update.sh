#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl gitMinimal jq coreutils
# shellcheck shell=bash

set -euo pipefail

base_url="https://downloads.claude.ai/claude-code-releases"
repo_root="$(git rev-parse --show-toplevel)"
package_dir="$repo_root/pkgs/claude-code"
manifest_file="$package_dir/manifest.json"
manifest_temp="$(mktemp "$package_dir/.manifest.json.XXXXXX")"
trap 'rm -f "$manifest_temp"' EXIT

version="$(curl --silent --show-error --fail --location "$base_url/latest")"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: latest endpoint returned an invalid version: $version" >&2
  exit 1
fi

curl --silent --show-error --fail --location \
  "$base_url/$version/manifest.json" \
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
          and (.binary | type == "string" and length > 0)
          and (.checksum | type == "string" and test("^[0-9a-f]{64}$"))
          and (.size | type == "number" and . > 0)
      )
  ' "$manifest_temp" >/dev/null; then
  echo "error: manifest for $version is incomplete or invalid" >&2
  exit 1
fi

mv "$manifest_temp" "$manifest_file"
echo "Claude Code manifest is pinned to $version."
