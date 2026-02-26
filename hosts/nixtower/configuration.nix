{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/workstation.nix
  ];

  networking.hostId = "1a14084a";

  boot.zfs.requestEncryptionCredentials = false;

  my.vfio = {
    enable = true;
    intel.enable = true;
  };

  my.rnnoise.micNodeName = "alsa_input.usb-Logitech_Yeti_GX_2428SGV014T8-00.mono-fallback";
}
