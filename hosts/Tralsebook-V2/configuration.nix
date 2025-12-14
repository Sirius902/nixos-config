{pkgs, ...}: {
  imports = [
    ../../modules/darwin/minimal.nix
  ];

  environment.systemPackages = [
    pkgs.shipwright
    pkgs.shipwright-ap
    pkgs._2ship2harkinian
  ];
}
