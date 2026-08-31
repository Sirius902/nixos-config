HOST := env_var_or_default(
  "HOST",
  `if [ "$(uname -s)" = Darwin ]; then scutil --get LocalHostName; else uname -n; fi`
)

NIX_FLAGS := '--extra-experimental-features "nix-command flakes"'

default:
    just --list

fmt:
    nix {{ NIX_FLAGS }} fmt .

check *FLAGS:
    nix {{ NIX_FLAGS }} flake check {{ FLAGS }}

update:
    ./patches/nixpkgs/update.py
    nix {{ NIX_FLAGS }} flake update --refresh
    git diff --quiet flake.lock patches/nixpkgs/pins.json || git commit -m "flake: update inputs" flake.lock patches/nixpkgs/pins.json
    nix {{ NIX_FLAGS }} run ".#update"

update-nixpkgs:
    ./patches/nixpkgs/update.py

prune-nixpkgs-pins *FLAGS:
    ./patches/nixpkgs/prune-pins.py {{ FLAGS }}

switch *FLAGS:
    nh os switch -H "{{ HOST }}" ".#" {{ FLAGS }}

boot *FLAGS:
    nh os boot -H "{{ HOST }}" ".#" {{ FLAGS }}

switch-darwin *FLAGS:
    nh darwin switch -H "{{ HOST }}" ".#" {{ FLAGS }}

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
