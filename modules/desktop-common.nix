{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gparted
    jetbrains-mono
    nautilus-python # Required for Open in WezTerm.
    qdirstat
    wl-clipboard
    vscodium
  ];
}
