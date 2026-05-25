{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/workstation.nix
    ../../modules/pipewire/crackle-fix.nix
  ];

  networking.hostId = "49e32584";

  boot.kernelModules = ["ntsync"];
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
}
