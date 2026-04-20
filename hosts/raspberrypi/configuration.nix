{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-3
    ../../modules/nixos/base.nix
    ./hardware-configuration.nix
  ];

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.kernelPackages = inputs.nixos-raspberrypi.packages.${pkgs.stdenv.hostPlatform.system}.linuxPackages_rpi3;

  hardware.enableRedistributableFirmware = true;

  networking.hostId = "4786fd98";

  my.tailscale.enable = true;

  environment.systemPackages = with pkgs; [
    ghostty.terminfo
    nvim
    libraspberrypi
    wakeonlan
  ];

  environment.pathsToLink = [
    "/share/terminfo"
  ];

  system.stateVersion = "26.05";
}
