{
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

  my.rnnoise.micNodeName = "alsa_input.usb-Razer_Inc_Razer_Seiren_Mini_UC2306L03301805-00.mono-fallback";
}
