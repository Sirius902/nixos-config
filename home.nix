{ inputs, isDesktop, ... }:

{ config, pkgs, lib, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "chris";
  home.homeDirectory = "/home/chris";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  dconf = pkgs.lib.mkIf isDesktop (
    let mkTuple = lib.hm.gvariant.mkTuple; in {
      enable = true;
      settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
      settings."org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = with pkgs.gnomeExtensions; [
          gsconnect.extensionUuid
        ];
      };
      settings."org/gnome/shell".favorite-apps = [
        "firefox.desktop"
        "org.wezfurlong.wezterm.desktop"
        "codium.desktop"
        "dev.zed.Zed.desktop"
        "org.gnome.Nautilus.desktop"
        "discord.desktop"
        "org.prismlauncher.PrismLauncher.desktop"
        "steam.desktop"
        "xivlauncher.desktop"
        "virt-manager.desktop"
      ];
      settings."org/gnome/desktop/interface".clock-format = "12h";
      settings."org/gtk/settings/file-chooser".clock-format = "12h";
      settings."org/gnome/mutter" = {
        edge-tiling = true;
        dynamic-workspaces = true;
        workspaces-only-on-primary = true;
      };
      settings."org/gnome/desktop/input-sources".sources = [ (mkTuple [ "xkb" "us" ]) (mkTuple [ "ibus" "mozc-on" ]) ];
      settings."org/gnome/desktop/background" = {
        picture-uri = "file:///home/chris/Pictures/Backgrounds/Screenshot from 2024-07-07 23-23-16.png";
        picture-uri-dark = "file:///home/chris/Pictures/Backgrounds/Screenshot from 2024-07-07 23-23-16.png";
      };
      settings."org/virt-manager/virt-manager/connections" = {
        autoconnect = [ "qemu:///system" ];
        uris = [ "qemu:///system" ];
      };
    }
  );

  programs.wezterm = pkgs.lib.mkIf isDesktop {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    extraConfig = builtins.readFile ./dotfiles/wezterm/wezterm.lua;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    defaultKeymap = "viins"; # Use Vim keybinds
    initExtra = "prompt pure";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # TODO: For some reason setting defaultEditor below isn't working.
  # Set editor to neovim.
  home.sessionVariables.EDITOR = "nvim";
  home.sessionVariables.VISUAL = "nvim";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = (if isDesktop then [ pkgs.gnomeExtensions.gsconnect ] else [ ]) ++ [
    # TODO: Add vimdiff alias somehow.
    pkgs.nvim
    pkgs.pure-prompt

    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/chris/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
