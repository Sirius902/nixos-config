{pkgs, ...}: {
  imports = [
    ./_2ship2harkinian.nix
    ./dusklight.nix
    ./shipwright.nix
    ./zelda64recomp.nix
  ];

  home.packages = with pkgs; [
    archipelago
    dusklight-ap
    poptracker
    xash3d-fwgs
  ];
}
