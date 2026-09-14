{pkgs, ...}: {
  imports = [./base.nix];

  home.packages = [pkgs.wrye-bash];
}
