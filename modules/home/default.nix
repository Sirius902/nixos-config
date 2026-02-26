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

  home.stateVersion = "23.11";

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

  # TODO: For some reason setting defaultEditor below isn't working.
  home.sessionVariables.EDITOR = "${pkgs.nvim}/bin/nvim";
  home.sessionVariables.VISUAL = "${pkgs.nvim}/bin/nvim";

  home.packages = [
    # TODO: Add vimdiff alias somehow.
    pkgs.nvim
    pkgs.pure-prompt
    pkgs.nixd
  ];

  programs.home-manager.enable = true;
}
