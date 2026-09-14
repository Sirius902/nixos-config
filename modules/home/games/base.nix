{pkgs, ...}: {
  imports = [
    ./dusklight.nix
    ./shipwright.nix
    ./zelda64recomp.nix
  ];

  home.packages = with pkgs; [
    _2ship2harkinian
    archipelago
    dusklight-ap
    poptracker
    xash3d-fwgs
  ];
}
