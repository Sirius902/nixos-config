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

  hardware.enableRedistributableFirmware = true;

  networking.hostId = "4786fd98";

  # FUTURE(Sirius902) https://github.com/NixOS/nixpkgs/pull/513771
  boot.kernel.sysctl."vm.mmap_rnd_bits" = 24;

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
