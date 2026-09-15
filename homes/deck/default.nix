{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/home/games/base.nix
    ../../modules/home/helix.nix
    ../../modules/home/zellij.nix

    # Every `bin/` entry in the profile, not a list of games: what Steam's
    # launcher does is fatal to any nixpkgs wrapper script, and nearly every
    # package is one. Declaring `apply` transforms home-manager's own profile
    # definition in place, so there is nothing here to keep in step with it.
    {options.home.path = lib.mkOption {apply = pkgs.wrapForSteam;};}
  ];

  home.username = "deck";
  home.homeDirectory = "/home/deck";
  home.stateVersion = "26.05";

  home.packages = [
    pkgs.croc
    pkgs.nix
    (pkgs.discord-canary.override {withMoonlight = true;})
  ];

  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
    };
  };

  # Activation otherwise resolves `nix-env` from the ambient `PATH`, so the
  # generation would depend on a Nix it does not carry, and could not update
  # the one the next deploy runs.
  nix.package = pkgs.nix;

  # SteamOS ships its own manpages and mime database, and nothing in a gamescope
  # session reads a Nix profile's copies.
  manual.manpages.enable = false;
  programs.man.enable = false;
  xdg.mime.enable = false;

  i18n.glibcLocales = pkgs.glibcLocales.override {
    allLocales = false;
    locales = ["en_US.UTF-8/UTF-8"];
  };
}
