{
  config,
  lib,
  ...
}: {
  imports = [
    ../../modules/darwin/minimal.nix
    ../../modules/darwin/linux-builder.nix
  ];

  home-manager.users = lib.genAttrs config.my.homeUsers (_: {
    imports = [
      ../../modules/home/games/_2ship2harkinian.nix
      ../../modules/home/games/dusklight.nix
      ../../modules/home/games/shipwright.nix
    ];
  });
}
