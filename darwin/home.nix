{ pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "chris";
  home.homeDirectory = "/Users/chris";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  programs.wezterm = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    extraConfig = builtins.readFile ../dotfiles/wezterm/wezterm.lua;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    defaultKeymap = "viins"; # Use Vim keybinds
    initExtra = "prompt pure";

    envExtra = ''
      . "$HOME/.cargo/env"
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.nvim
    pkgs.pure-prompt
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
