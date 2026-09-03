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
    pkgs._2ship2harkinian
  ];

  home-manager.users = lib.genAttrs config.my.homeUsers (_: {
    imports = [
      ../../modules/home/dusklight.nix
      ../../modules/home/shipwright.nix
    ];
  });
}
