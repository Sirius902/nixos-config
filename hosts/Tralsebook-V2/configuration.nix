{pkgs, ...}: {
  imports = [
    ../../modules/darwin/minimal.nix
    ../../modules/darwin/linux-builder.nix
  ];

  environment.systemPackages = [
    pkgs.dusklight
    pkgs.shipwright
    pkgs.shipwright-ap
    pkgs._2ship2harkinian
  ];
}
