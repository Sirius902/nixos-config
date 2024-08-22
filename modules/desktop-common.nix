{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gparted
    jetbrains.idea-community
    krita
    nautilus-python # Required for Open in WezTerm.
    qdirstat
    wl-clipboard
    xclip
    vscodium
  ];
}
