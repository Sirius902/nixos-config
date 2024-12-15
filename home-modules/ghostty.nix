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

    # NOTE(Sirius902) Workaround for ghostty's PATH not being respected with nix-darwin.
    programs.zsh.initExtra = lib.mkIf stdenv.isDarwin ''
      if [[ "$TERM_PROGRAM" = ghostty ]]; then
        if [[ -n "$GHOSTTY_RESOURCES_DIR" ]]; then
          source "$GHOSTTY_RESOURCES_DIR"/shell-integration/bash/ghostty.bash
        fi
        if [[ -n "$GHOSTTY_BIN_DIR" &&  :"$PATH": != *:"$GHOSTTY_BIN_DIR":* ]]; then
          PATH=$GHOSTTY_BIN_DIR''${PATH:+:$PATH}
        fi
      fi
    '';
  }
