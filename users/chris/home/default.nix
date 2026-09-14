{
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs) stdenv;
in {
  imports = [
    ../../../modules/home/helix.nix
    ../../../modules/home/zellij.nix
    ./git.nix
    ./jujutsu.nix
  ];

  home.username = "chris";
  home.homeDirectory =
    if stdenv.hostPlatform.isDarwin
    then "/Users/chris"
    else "/home/chris";

  home.stateVersion = "26.05";

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # Avoid double compinit — NixOS already calls it in /etc/zshrc.
    completionInit = "";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    defaultKeymap = "viins";

    initContent =
      ''
        autoload -Uz edit-command-line
        zle -N edit-command-line
        bindkey '^x^e' edit-command-line

        bindkey '^R' history-incremental-search-backward
        prompt pure

        scratch() {
          local dir=$(mktemp -d)
          echo "Scratch dir: $dir"
          (cd "$dir" && exec $SHELL)
          rm -rf "$dir"
          echo "Cleaned up $dir"
        }
      ''
      + (lib.optionalString stdenv.hostPlatform.isLinux ''
        alias open='xdg-open 2>/dev/null'

        launch() {
          setsid --fork "$@" </dev/null >/dev/null 2>&1
          exit
        }
      '')
      + (lib.optionalString stdenv.hostPlatform.isDarwin ''
        export PATH="$HOME/.local/bin:$PATH"
        export PATH="/opt/homebrew/bin:$PATH"
        export PATH="/usr/local/zfs/bin:$PATH"
      '');

    envExtra = lib.mkIf stdenv.hostPlatform.isDarwin ''
      export SSH_AUTH_SOCK="$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.helix.extraPackages = [
    pkgs.nixd
    pkgs.rust-analyzer
    pkgs.taplo
    pkgs.luaPackages.teal-language-server
    pkgs.zls
  ];

  home.packages =
    [
      # TODO: Add vimdiff alias somehow.
      pkgs.nvim
      pkgs.pure-prompt
    ]
    ++ (lib.optionals (!stdenv.hostPlatform.isDarwin) [
      pkgs.claude-code
      pkgs.codex
    ]);

  programs.home-manager.enable = true;
}
