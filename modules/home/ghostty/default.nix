{
  options,
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs) stdenv;
  os = (lib.systems.parse.mkSystemFromString stdenv.system).kernel.name;
in {
  # NOTE(Sirius902) ghostty currently can't build on macOS from the flake.
  home.packages = lib.mkIf stdenv.hostPlatform.isLinux [
    pkgs.ghostty
  ];

  home.file.".config/ghostty/config".source =
    {
      "linux" = ../../../dotfiles/ghostty/config;
      "darwin" = ../../../dotfiles/ghostty/config-darwin;
    }
    .${
      os
    };

  # NOTE(Sirius902) Workaround for ghostty's PATH not being respected with nix-darwin.
  programs.zsh = let
    # TODO(Sirius902) Just use initContent when initExtra is deprecated in stable home-manager.
    initAttr =
      if lib.hasAttrByPath ["initContent"] options.programs.zsh
      then "initContent"
      else "initExtra";
  in {
    ${initAttr} = lib.mkIf stdenv.hostPlatform.isDarwin ''
      if [[ "$TERM_PROGRAM" = ghostty ]]; then
        if [[ -n "$GHOSTTY_RESOURCES_DIR" ]]; then
          source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
        fi
        if [[ -n "$GHOSTTY_BIN_DIR" &&  :"$PATH": != *:"$GHOSTTY_BIN_DIR":* ]]; then
          PATH=$GHOSTTY_BIN_DIR''${PATH:+:$PATH}
        fi
      fi
    '';
  };
}
