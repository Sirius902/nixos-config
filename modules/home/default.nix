{
  config,
  options,
  pkgs,
  lib,
  isHeadless,
  isVm,
  ...
}: let
  inherit (pkgs) stdenv;
  isLinuxDesktop = stdenv.isLinux && !isHeadless;
in {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "chris";
  home.homeDirectory =
    if stdenv.isDarwin
    then "/Users/chris"
    else "/home/chris";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  dconf =
    lib.mkIf isLinuxDesktop
    {
      enable = true;
      settings."org/virt-manager/virt-manager/connections" = {
        autoconnect = ["qemu:///system"];
        uris = ["qemu:///system"];
      };
    };

  gtk = lib.mkIf isLinuxDesktop ({
      enable = true;
      gtk3.extraConfig."gtk-application-prefer-dark-theme" = 1;
    }
    // lib.optionalAttrs (lib.versionAtLeast config.home.version.release "25.11") {
      # Workaround for KDE being annoying.
      gtk2.force = true;
    });

  programs.librewolf =
    lib.mkIf isLinuxDesktop
    {
      enable = true;
      settings = {
        "identity.fxaccounts.enabled" = true;
        "webgl.disabled" = false;
        "privacy.resistFingerprinting" = false;
        "privacy.fingerprintingProtection" = true;
        "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme,-JSDateTimeUTC";
        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown.cookies" = false;
        "network.cookie.lifetimePolicy" = 0;
      };
    };

  programs.zsh = let
    # TODO(Sirius902) Just use initContent when initExtra is deprecated in stable home-manager.
    initAttr =
      if lib.hasAttrByPath ["initContent"] options.programs.zsh
      then "initContent"
      else "initExtra";
  in {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    defaultKeymap = "viins"; # Use Vim keybinds

    ${initAttr} =
      ''
        bindkey '^R' history-incremental-search-backward
        prompt pure
      ''
      + (lib.optionalString stdenv.isLinux ''
        alias open='xdg-open 2>/dev/null'
      '')
      + (lib.optionalString stdenv.isDarwin ''
        export PATH="/opt/homebrew/bin:$PATH"
      '');

    envExtra = lib.mkIf stdenv.isDarwin ''
      . "$HOME/.cargo/env"
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # TODO: For some reason setting defaultEditor below isn't working.
  # Set editor to neovim.
  home.sessionVariables.EDITOR = "${pkgs.nvim}/bin/nvim";
  home.sessionVariables.VISUAL = "${pkgs.nvim}/bin/nvim";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages =
    [
      # TODO: Add vimdiff alias somehow.
      pkgs.nvim
      pkgs.pure-prompt
      pkgs.nixd

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
    ]
    ++ (lib.optional (!isVm) pkgs.smartmontools);

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
