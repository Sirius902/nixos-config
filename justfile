SUDO := env_var_or_default(
  "SUDO",
  `if [ "$(uname -s)" = Darwin ]; then echo sudo; else echo doas; fi`
)

HOST := env_var_or_default(
  "HOST",
  `if [ "$(uname -s)" = Darwin ]; then scutil --get LocalHostName; else uname -n; fi`
)

NIX_FLAGS := '--extra-experimental-features "nix-command flakes"'

default:
    just --list

fmt:
    nix {{ NIX_FLAGS }} fmt .

update:
    nix {{ NIX_FLAGS }} flake update
    git diff --quiet flake.lock || git commit -m "flake: update inputs" flake.lock
    nix {{ NIX_FLAGS }} run ".#update"

prefetch-inputs:
    nix {{ NIX_FLAGS }} flake prefetch-inputs

switch *FLAGS: prefetch-inputs
    {{ SUDO }} nixos-rebuild switch --flake ".#{{ HOST }}" {{ FLAGS }}

boot *FLAGS: prefetch-inputs
    {{ SUDO }} nixos-rebuild boot --flake ".#{{ HOST }}" {{ FLAGS }}

switch-darwin *FLAGS: prefetch-inputs
    {{ SUDO }} darwin-rebuild switch --flake ".#{{ HOST }}" {{ FLAGS }}

switch-to-configuration drv:
    nix-env -p /nix/var/nix/profiles/system --set "{{ drv }}"
    "{{ drv }}/bin/switch-to-configuration" switch

build-raspberrypi:
    nix {{ NIX_FLAGS }} build --no-link --print-out-paths ".#nixosConfigurations.raspberrypi.config.system.build.toplevel"

build-iso:
    nix {{ NIX_FLAGS }} build --no-link --print-out-paths ".#nixosConfigurations.iso.config.system.build.isoImage"

anywhere ip:
    #!/usr/bin/env bash
    set -euo pipefail
    temp=$(mktemp -d)
    trap "rm -rf $temp" EXIT
    keydir="/persist/config/sops/age"
    mkdir -p "$temp/$keydir"
    rsync -a "$keydir/keys.txt" "$temp/$keydir/keys.txt"
    nix {{ NIX_FLAGS }} run github:nix-community/nixos-anywhere -- --extra-files "$temp" --flake ".#{{ HOST }}" "root@{{ ip }}"

anywhere-test *FLAGS:
    nix {{ NIX_FLAGS }} run github:nix-community/nixos-anywhere -- --flake ".#{{ HOST }}" --vm-test {{ FLAGS }}
