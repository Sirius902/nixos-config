{ pkgs, ... }:

{
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  hardware.keyboard.zsa.enable = true;

  environment.systemPackages = with pkgs; [
    gparted
    jetbrains.idea-community
    keymapp
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
