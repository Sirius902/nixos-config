{pkgs, ...}: {
  imports = [./zelda64recomp.nix];

  home.packages = with pkgs; [
    archipelago
    poptracker
    dusklight
    dusklight-rando
    dusklight-ap
    shipwright
    shipwright_stable
    _2ship2harkinian
    shipwright-ap
    wrye-bash
  ];
}
