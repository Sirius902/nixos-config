{ pkgs, ... }:

{
  imports = [
    ../modules/desktop-common.nix
    ../modules/secure-boot.nix
    ../modules/documentation.nix
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  environment.systemPackages = with pkgs; [
    shipwright
  ];
}
