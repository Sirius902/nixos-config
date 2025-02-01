{pkgs, ...}: {
  imports = [./default.nix];

  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };
}
