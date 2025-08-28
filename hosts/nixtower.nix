{lib, ...}: {
  imports = [./nixlee.nix];

  my.rnnoise.micNodeName = lib.mkForce "alsa_input.usb-Logitech_Yeti_GX_2428SGV014T8-00.mono-fallback";
}
