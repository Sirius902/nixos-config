{
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs) stdenv;
in {
  home.username = "chris";
  home.homeDirectory =
    if stdenv.hostPlatform.isDarwin
    then "/Users/chris"
    else "/home/chris";

  home.stateVersion = "26.05";

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    defaultKeymap = "viins";

    initContent =
      ''
        bindkey '^R' history-incremental-search-backward
        prompt pure
      ''
      + (lib.optionalString stdenv.hostPlatform.isLinux ''
        alias open='xdg-open 2>/dev/null'

        launch() {
          setsid --fork "$@" </dev/null >/dev/null 2>&1
          exit
        }
      '')
      + (lib.optionalString stdenv.hostPlatform.isDarwin ''
        export PATH="/opt/homebrew/bin:$PATH"
      '');

    envExtra = lib.mkIf stdenv.hostPlatform.isDarwin ''
      . "$HOME/.cargo/env"
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.helix = {
    enable = true;
    defaultEditor = true;
    extraPackages = [
      pkgs.nixd
      pkgs.rust-analyzer
      pkgs.zls
    ];
    extraConfig = ''
      theme = "kanagawa"

      [editor]
      line-number = "relative"

      [editor.indent-guides]
      render = true
      # character = "┊"

      # FUTURE(Sirius902) Enable sticky context once this is resolved.
      # https://github.com/helix-editor/helix/issues/396
    '';
  };

  home.packages = [
    # TODO: Add vimdiff alias somehow.
    pkgs.nvim
    pkgs.pure-prompt
  ];

  programs.home-manager.enable = true;
}
