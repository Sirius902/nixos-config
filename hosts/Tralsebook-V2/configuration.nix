{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/darwin/minimal.nix
    ../../modules/darwin/linux-builder.nix
  ];

  environment.systemPackages = [
    pkgs.dusklight
    pkgs._2ship2harkinian
  ];

  home-manager.users = lib.genAttrs config.my.homeUsers (_: {
    imports = [../../modules/home/shipwright.nix];
  });
}
