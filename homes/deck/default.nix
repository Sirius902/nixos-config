{
  basePkgs,
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

  # What Game Mode launches, as opposed to what `modules/home` installs. A game
  # added there and missed here still installs and still runs from a terminal;
  # it fails on its first launch from Game Mode.
  #
  # Substituted onto the package set rather than added as an overlay because
  # `dusklight` is also a build input — of `dusklight-ap` and of both mod
  # bundles — and an overlay feeds a wrapper carrying no `src` back into those.
  _module.args.pkgs = lib.mkForce (basePkgs
    // lib.genAttrs [
      "_2ship2harkinian"
      "archipelago"
      "dusklight"
      "dusklight-ap"
      "poptracker"
      "shipwright"
      "shipwright_stable"
      "shipwright-ap"
      "xash3d-fwgs"
      "zelda64recomp"
    ] (name: basePkgs.wrapForSteam basePkgs.${name}));

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
