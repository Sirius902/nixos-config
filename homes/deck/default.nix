{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/home/games/base.nix
    ../../modules/home/helix.nix
    ../../modules/home/zellij.nix
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

  # Every `bin/` entry in the profile, not a list of games: what Steam's
  # launcher does is fatal to any nixpkgs wrapper script, and nearly every
  # package is one. The body repeats home-manager's own `home.path`, which
  # `wrapForSteam` takes whole.
  home.path = lib.mkForce (pkgs.wrapForSteam (pkgs.buildEnv {
    name = "home-manager-path";
    paths = config.home.packages;
    inherit (config.home) extraOutputsToInstall;
    postBuild = config.home.extraProfileCommands;
  }));

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
