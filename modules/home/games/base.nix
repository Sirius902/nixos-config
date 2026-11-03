{pkgs, ...}: {
  imports = [
    ./_2ship2harkinian.nix
    ./dusklight.nix
    ./shipwright.nix
    ./zelda64recomp.nix
  ];

  home.packages = with pkgs; [
    archipelago
    poptracker
    rpcs3
    xash3d-fwgs
  ];
}
