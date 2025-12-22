SUDO := env_var_or_default(
  "SUDO",
  `if [ "$(uname -s)" = Darwin ]; then echo sudo; else echo doas; fi`
)

HOST := env_var_or_default(
  "HOST",
  `if [ "$(uname -s)" = Darwin ]; then scutil --get LocalHostName; else hostname; fi`
)

NIX_FLAGS := '--extra-experimental-features "nix-command flakes"'

default:
    just --list

fmt:
    nix {{ NIX_FLAGS }} fmt .

prefetch-inputs:
    nix {{ NIX_FLAGS }} flake prefetch-inputs

switch *FLAGS: prefetch-inputs
    {{ SUDO }} nixos-rebuild switch --flake "path:.#{{ HOST }}" {{ FLAGS }}

switch-darwin *FLAGS: prefetch-inputs
    {{ SUDO }} darwin-rebuild switch --flake "path:.#{{ HOST }}" {{ FLAGS }}

build-raspberrypi:
    nix {{ NIX_FLAGS }} build "path:.#nixosConfigurations.raspberrypi.config.system.build.toplevel"

build-iso:
    nix {{ NIX_FLAGS }} build "path:.#nixosConfigurations.iso.config.system.build.isoImage"

anywhere ip:
    #!/usr/bin/env bash
    set -euo pipefail
    temp=$(mktemp -d)
    trap "rm -rf $temp" EXIT
    keydir="/persist/config/sops/age"
    mkdir -p "$temp/$keydir"
    rsync -a "$keydir/keys.txt" "$temp/$keydir/keys.txt"
    nix {{ NIX_FLAGS }} run github:nix-community/nixos-anywhere -- --extra-files "$temp" --flake "path:.#{{ HOST }}" "root@{{ ip }}"

anywhere-test *FLAGS:
    nix {{ NIX_FLAGS }} run github:nix-community/nixos-anywhere -- --flake "path:.#{{ HOST }}" --vm-test {{ FLAGS }}
