host := `cat ./host`

default:
    just --list

fmt:
    nix --extra-experimental-features "nix-command flakes" fmt .

switch *FLAGS:
    nixos-rebuild --flake "path:.#{{ host }}" switch {{ FLAGS }}

switch-darwin *FLAGS:
    darwin-rebuild switch --flake "path:.#{{ host }}" {{ FLAGS }}

anywhere host ip:
    #!/usr/bin/env bash
    temp=$(mktemp -d)
    trap "rm -rf $temp" EXIT
    keydir="/persist/config/sops/age"
    mkdir -p "$temp/$keydir"
    rsync -a "$keydir/keys.txt" "$temp/$keydir/keys.txt"
    nix run github:nix-community/nixos-anywhere -- --extra-files "$temp" --flake ".#{{ host }}" "root@{{ ip }}"

anywhere-test host *FLAGS:
    nix run github:nix-community/nixos-anywhere -- --flake ".#{{ host }}" --vm-test {{ FLAGS }}
