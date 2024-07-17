host := "nixlee"

default:
    just --list

fmt:
    nix --extra-experimental-features "nix-command flakes" fmt

switch:
    nixos-rebuild --flake "path:.#{{ host }}" switch
