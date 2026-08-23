#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl gawk gitMinimal gnugrep gnused nix nix-update jq coreutils
# shellcheck shell=bash

set -euo pipefail

base_url="https://github.com/denoland/rusty_v8/releases/download"
repo_root="$(git rev-parse --show-toplevel)"
package_dir="$repo_root/overlays/codex"
archive_file="$package_dir/librusty_v8.nix"
binding_file="$package_dir/librusty_v8_src_binding.nix"
temp_dir="$(mktemp -d)"
archive_temp="$temp_dir/librusty_v8.nix"
binding_temp="$temp_dir/librusty_v8_src_binding.nix"
trap 'rm -f "$archive_temp" "$binding_temp"; rmdir "$temp_dir"' EXIT

github_auth=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  github_auth=(-u ":$GITHUB_TOKEN")
fi

latest_tag="$(
  curl "${github_auth[@]}" --silent --show-error --fail --location \
    https://api.github.com/repos/openai/codex/releases/latest \
    | jq --exit-status --raw-output '.tag_name | select(test("^rust-v[0-9]+\\.[0-9]+\\.[0-9]+$"))'
)"
latest_version="${latest_tag#rust-v}"
cargo_lock="$(curl "${github_auth[@]}" --silent --show-error --fail --location \
  "https://raw.githubusercontent.com/openai/codex/$latest_tag/codex-rs/Cargo.lock")"
v8_version="$(awk '
  $0 == "name = \"v8\"" { in_v8 = 1; next }
  in_v8 && $1 == "version" { print substr($3, 2, length($3) - 2); exit }
' <<<"$cargo_lock")"

if [[ -z "$v8_version" ]]; then
  echo "error: v8 crate version is missing from $latest_tag/codex-rs/Cargo.lock" >&2
  exit 1
fi

prefetch() {
  nix-prefetch-url --type sha256 "$1"
}

archive_x86_64_linux="$(prefetch "$base_url/v$v8_version/librusty_v8_release_x86_64-unknown-linux-gnu.a.gz")"
archive_aarch64_linux="$(prefetch "$base_url/v$v8_version/librusty_v8_release_aarch64-unknown-linux-gnu.a.gz")"
archive_aarch64_darwin="$(prefetch "$base_url/v$v8_version/librusty_v8_release_aarch64-apple-darwin.a.gz")"
binding_x86_64_linux="$(prefetch "$base_url/v$v8_version/src_binding_release_x86_64-unknown-linux-gnu.rs")"
binding_aarch64_linux="$(prefetch "$base_url/v$v8_version/src_binding_release_aarch64-unknown-linux-gnu.rs")"
binding_aarch64_darwin="$(prefetch "$base_url/v$v8_version/src_binding_release_aarch64-apple-darwin.rs")"

sed \
  -e "s|@version@|$v8_version|g" \
  -e "s|@x86_64_linux@|$archive_x86_64_linux|g" \
  -e "s|@aarch64_linux@|$archive_aarch64_linux|g" \
  -e "s|@aarch64_darwin@|$archive_aarch64_darwin|g" \
  >"$archive_temp" <<'EOF'
# auto-generated file -- DO NOT EDIT!
{fetchLibrustyV8}:
fetchLibrustyV8 {
  version = "@version@";
  shas = {
    x86_64-linux = "@x86_64_linux@";
    aarch64-linux = "@aarch64_linux@";
    aarch64-darwin = "@aarch64_darwin@";
  };
}
EOF

sed \
  -e "s|@version@|$v8_version|g" \
  -e "s|@x86_64_linux@|$binding_x86_64_linux|g" \
  -e "s|@aarch64_linux@|$binding_aarch64_linux|g" \
  -e "s|@aarch64_darwin@|$binding_aarch64_darwin|g" \
  >"$binding_temp" <<'EOF'
# auto-generated file -- DO NOT EDIT!
{fetchLibrustyV8SrcBinding}:
fetchLibrustyV8SrcBinding {
  version = "@version@";
  shas = {
    x86_64-linux = "@x86_64_linux@";
    aarch64-linux = "@aarch64_linux@";
    aarch64-darwin = "@aarch64_darwin@";
  };
}
EOF

if ! cmp --silent "$archive_temp" "$archive_file"; then
  mv "$archive_temp" "$archive_file"
fi
if ! cmp --silent "$binding_temp" "$binding_file"; then
  mv "$binding_temp" "$binding_file"
fi

nix-update --flake --commit --version "$latest_version" codex

echo "Rusty V8 is pinned to $v8_version for Codex $latest_tag."
