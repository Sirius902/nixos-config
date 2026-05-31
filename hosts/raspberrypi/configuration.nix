{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/nixos/base.nix
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = {inherit inputs;};
      home-manager.users.chris = import ../../modules/home/default.nix;
    }
  ];

  boot.kernelPackages = pkgs.linuxPackages;
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  system.build.updateFirmware = let
    fw = "${pkgs.raspberrypifw}/share/raspberrypi/boot";
    uboot = pkgs.ubootRaspberryPi3_64bit;
  in
    pkgs.writeShellScript "update-firmware" ''
      set -euo pipefail
      fwdir=/boot/firmware

      echo "Backing up $fwdir to $fwdir.bak..."
      rm -rf "$fwdir.bak"
      cp -a "$fwdir" "$fwdir.bak"

      echo "Updating firmware..."
      cp ${fw}/bootcode.bin ${fw}/start.elf ${fw}/fixup.dat "$fwdir/"
      cp ${fw}/bcm2710-rpi-3-b.dtb "$fwdir/"
      cp ${uboot}/u-boot.bin "$fwdir/u-boot-rpi3.bin"

      sync
      echo "Done. Reboot to use new firmware."
      echo "If boot fails, restore from $fwdir.bak"
    '';

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
