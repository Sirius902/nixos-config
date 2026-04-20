{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/darwin/minimal.nix
  ];

  nix = {
    linux-builder = {
      enable = true;
      ephemeral = true;
      config = {
        virtualisation = {
          cores = 8;
          darwin-builder.memorySize = 8 * 1024;
          diskSize = lib.mkForce (40 * 1024);
        };
      };
    };
    # NOTE(Sirius902) Required for linux-builder
    settings.trusted-users = ["@admin"];
  };

  environment.systemPackages = [
    pkgs.shipwright
    pkgs.shipwright-ap
    pkgs._2ship2harkinian
  ];
}
