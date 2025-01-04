{pkgs, ...}: {
  imports = [
    ../modules/desktop-common.nix
    ../modules/secure-boot.nix
    ../modules/documentation.nix
    ../modules/ssl-dev.nix
    ../modules/xrdp.nix
  ];

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  environment.systemPackages = with pkgs; [
    shipwright
  ];
}
