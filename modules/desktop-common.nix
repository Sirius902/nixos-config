{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gparted
    krita
    nautilus-python # Required for Open in WezTerm.
    qdirstat
    wl-clipboard
    vscodium
  ];
}
