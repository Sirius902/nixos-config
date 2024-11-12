{ pkgs, ... }:

{
  imports = [
    ../modules/desktop-common.nix
    ../modules/secure-boot.nix
    ../modules/documentation.nix
  ];

  environment.systemPackages = with pkgs; [
    shipwright
  ];
}
