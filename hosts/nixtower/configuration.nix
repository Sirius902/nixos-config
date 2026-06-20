{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/workstation.nix
    ../../modules/pipewire/nommo-volume-fix.nix
  ];

  networking.hostId = "1a14084a";

  my.memory = {
    enable = true;
    ramGiB = 32; # derives: zram 33%, swappiness 133, ARC 12G (lower arcMaxGiB if big VMs need the RAM)
  };

  boot.zfs.requestEncryptionCredentials = false;

  my.vfio = {
    enable = true;
    intel.enable = true;
  };

  my.rnnoise.micNodeName = "alsa_input.usb-Razer_Inc_Razer_Seiren_Mini_UC2306L03301805-00.mono-fallback";
}
