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
    # It is available only because home-manager's own declaration sets no
    # `apply`, and an option takes at most one.
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

  # home-manager only feeds `LOCALE_ARCHIVE_2_27`, which nothing Steam launches
  # reads, while `wrapForSteam` sets `LOCALE_ARCHIVE`. Naming the archive it
  # already references keeps the generation from carrying a second one that no
  # substituter has.
  i18n.glibcLocales = pkgs.glibcLocalesUtf8;
}
