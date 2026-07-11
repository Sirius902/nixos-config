{pkgs, ...}: {
  home.packages = with pkgs; [
    archipelago
    poptracker
    dusklight
    dusklight-rando
    shipwright
    _2ship2harkinian
    shipwright-ap
    zelda64recomp
    wrye-bash
  ];
}
