{
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs) stdenv;
in {
  imports = [
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
      pkgs.taplo
      pkgs.zls
    ];
    extraConfig = ''
      theme = "kanagawa"

      [editor]
      line-number = "relative"
      insert-final-newline = true
      trim-trailing-whitespace = true

      [editor.indent-guides]
      render = true
      # character = "┊"

      [keys.normal]
      Y = "yank_joined"
      # Stage/view diff hunks via lazygit; Helix has no builtin staging.
      # https://github.com/helix-editor/helix/wiki/Recipes
      C-g = [":write-all", ":insert-output lazygit >/dev/tty", ":redraw", ":reload-all"]

      [keys.select]
      Y = "yank_joined"

      # FUTURE(Sirius902) Enable sticky context once this is resolved.
      # https://github.com/helix-editor/helix/issues/396
    '';
    # FUTURE(Sirius902) Remove once this is fixed from taplo I guess.
    # https://github.com/helix-editor/helix/pull/9915#issuecomment-2214001123
    languages = {
      name = "toml";
      roots = ["."];
    };
  };

  programs.zellij = {
    enable = true;
    extraConfig = builtins.readFile ../../../dotfiles/zellij/config.kdl;
  };

  home.packages =
    [
      pkgs.lazygit
      # TODO: Add vimdiff alias somehow.
      pkgs.nvim
      pkgs.pure-prompt
    ]
    ++ (lib.optionals (!stdenv.hostPlatform.isDarwin) [pkgs.claude-code]);

  programs.home-manager.enable = true;
}
