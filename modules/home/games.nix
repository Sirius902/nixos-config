{pkgs, ...}: {
  imports = [
    ./dusklight.nix
    ./shipwright.nix
    ./zelda64recomp.nix
  ];

  home.packages = with pkgs; [
    archipelago
    poptracker
    dusklight-ap
    _2ship2harkinian
    wrye-bash
  ];
}
