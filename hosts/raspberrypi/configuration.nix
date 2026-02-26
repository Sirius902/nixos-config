{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/nixos/base.nix
    ./hardware-configuration.nix
  ];

  # Cross-compile sops-install-secrets because building with QEMU will not
  # finish before the heat death of the universe
  sops.package = let
    pkgsCross = import inputs.nixpkgs {
      localSystem = "x86_64-linux";
      crossSystem = "aarch64-linux";
    };
  in
    (pkgsCross.callPackage inputs.sops-nix {}).sops-install-secrets;

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_rpi3;
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
