#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl gitMinimal jq nix
# shellcheck shell=bash

set -euo pipefail

base=25
line="Oracle GraalVM $base Innovation"

gds=https://gds.oracle.com/api/20220101
product=D53FAE8052773FFAE0530F15000AA6C6

repo_root="$(git rev-parse --show-toplevel)"
sources_file=overlays/graalvm-oracle/sources.json

artifacts() {
  curl --silent --show-error --fail --get "$gds/artifacts" \
    --data-urlencode "productId=$product" \
    --data-urlencode "status=PUBLISHED" \
    --data-urlencode "metadata=isBase:True" \
    --data-urlencode "metadata=edition:ee" \
    --data-urlencode "responseFields=id" \
    --data-urlencode "responseFields=checksum" \
    --data-urlencode "responseFields=metadata" \
    --data-urlencode "sortBy=timeCreated" \
    --data-urlencode "sortOrder=DESC" \
    --data-urlencode "limit=100" \
    "$@"
}

newest_base="$(artifacts | jq --raw-output '
  [.items[].metadata[]? | select(.key == "java") | .value
    | capture("^jdk(?<n>[0-9]+)$").n | tonumber]
  | max // empty
')"
if [[ -n "$newest_base" ]] && ((newest_base > base)); then
  echo "warning: Oracle GraalVM has builds on JDK $newest_base; graalvm-oracle follows JDK $base (base= in overlays/graalvm-oracle/update.sh)" >&2
fi

# Oracle uploads each platform separately, so only a version every platform has counts as released.
release="$(artifacts \
  --data-urlencode "metadata=java:jdk$base" \
  --data-urlencode "displayName=$line" |
  jq '
    {
      "aarch64-darwin": "macos/aarch64",
      "aarch64-linux": "linux/aarch64",
      "x86_64-linux": "linux/amd64"
    } as $systems
    | [ .items[]
        | (.metadata | from_entries) as $m
        | select(($m.version // "") | test("^[0-9]+(\\.[0-9]+)+$"))
        | {version: $m.version, target: "\($m.os)/\($m.arch)", id, checksum} ]
    | group_by(.version)
    | map(
        INDEX(.target) as $builds
        | select(all($systems[]; $builds[.] != null))
        | {version: .[0].version, platforms: ($systems | map_values($builds[.] | {id, checksum}))}
      )
    | max_by(.version | split(".") | map(tonumber))
  ')"
if [[ "$release" == null ]]; then
  echo "error: no '$line' release has builds for every platform" >&2
  exit 1
fi

version="$(jq --raw-output .version <<<"$release")"
old_version="$(jq --raw-output .version "$repo_root/$sources_file")"

rows="$(jq --raw-output '.platforms | to_entries[] | [.key, .value.id, .value.checksum] | @tsv' <<<"$release")"
platforms='{}'
while IFS=$'\t' read -r system id checksum; do
  if [[ ! "$id" =~ ^[[:alnum:]]+$ || ! "$checksum" =~ ^[[:xdigit:]]{64}$ ]]; then
    echo "error: unexpected artifact id '$id' or checksum '$checksum' for $system" >&2
    exit 1
  fi
  url="$gds/artifacts/$id/content"
  location="$(curl --silent --show-error --fail --head --output /dev/null --write-out '%{redirect_url}' "$url")"
  name="${location%%\?*}"
  name="${name##*/}"
  if [[ ! "$name" =~ ^graalvm-[[:alnum:]._+-]+\.tar\.gz$ ]]; then
    echo "error: $url redirects to '$location', not a GraalVM tarball" >&2
    exit 1
  fi
  hash="$(nix --extra-experimental-features nix-command hash convert --hash-algo sha256 --to sri "$checksum")"
  platforms="$(jq --arg system "$system" --arg name "$name" --arg url "$url" --arg hash "$hash" \
    '.[$system] = {name: $name, url: $url, hash: $hash}' <<<"$platforms")"
done <<<"$rows"

sources="$(jq --null-input --arg version "$version" --argjson platforms "$platforms" \
  '{version: $version, platforms: $platforms}')"
# Oracle can re-upload a build under the same version, so compare the pins, not just the version.
if [[ "$sources" == "$(<"$repo_root/$sources_file")" ]]; then
  echo "graalvm-oracle is already at $version."
  exit 0
fi
printf '%s\n' "$sources" >"$repo_root/$sources_file"

git -C "$repo_root" commit --only \
  --message "graalvm-oracle: $old_version -> $version" \
  -- "$sources_file"
