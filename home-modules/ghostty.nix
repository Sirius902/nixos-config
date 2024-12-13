{
  pkgs,
  lib,
  isHeadless,
  ghostty,
  ...
}: let
  inherit (pkgs) stdenv;
  os = builtins.elemAt (lib.splitString "-" stdenv.system) 1;
in
  lib.mkIf (!isHeadless) {
    # NOTE(Sirius902) ghostty currently can't build on macOS from the flake.
    home.packages = lib.mkIf stdenv.isLinux [
      ghostty.packages.${stdenv.system}.default
    ];

    home.file.".config/ghostty/config".source =
      {
        "linux" = ../dotfiles/ghostty/config;
        "darwin" = ../dotfiles/ghostty/config-darwin;
      }
      .${os};
  }
