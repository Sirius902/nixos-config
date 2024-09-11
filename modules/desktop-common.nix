{ pkgs, ... }:

{
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  environment.systemPackages = with pkgs; [
    gparted
    jetbrains.idea-community
    krita
    nautilus-python # Required for Open in WezTerm.
    qdirstat
    wl-clipboard
    xclip
    vscodium
    libreoffice-qt
    hunspell
  ];
}
