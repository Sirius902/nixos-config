{lib, ...}: {
  imports = [./sirius-lee.nix];

  boot.zfs.requestEncryptionCredentials = false;

  my.vfio = {
    amd.enable = lib.mkForce false;
    intel.enable = true;
  };

  my.rnnoise.micNodeName = lib.mkForce "alsa_input.usb-Logitech_Yeti_GX_2428SGV014T8-00.mono-fallback";
}
