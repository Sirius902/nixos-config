{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/workstation.nix
    ../../modules/pipewire/crackle-fix.nix
  ];

  networking.hostId = "49e32584";

  my.memory = {
    enable = true;
    ramGiB = 64; # derives: zram 25%, swappiness 133, ARC 24G
  };

  boot.kernelModules = ["ntsync" "nct6683"];
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  services.tailscale.useRoutingFeatures = "client";

  my.vfio = {
    enable = true;
    amd.enable = true;
    amdgpu.enable = true;
  };

  my.rnnoise.micNodeName = "alsa_input.usb-HP__Inc_HyperX_SoloCast-00.iec958-stereo";

  environment.systemPackages = with pkgs; [
    flatpak
    librepods
  ];

  system.extraDependencies = [pkgs.shipwright_stable];
}
