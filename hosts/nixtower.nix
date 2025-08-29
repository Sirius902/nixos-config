{
  lib,
  pkgs,
  ...
}: {
  imports = [./nixlee.nix];

  specialisation.lts-kernel.configuration = {
    system.nixos.tags = ["lts"];
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_12;
  };

  my.rnnoise.micNodeName = lib.mkForce "alsa_input.usb-Logitech_Yeti_GX_2428SGV014T8-00.mono-fallback";
}
