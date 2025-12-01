{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../modules/desktop/full.nix
    # ../modules/desktop/gnome/full.nix
    # ../modules/desktop/ibus.nix
    ../modules/desktop/cosmic/full.nix
    # ../modules/desktop/kde/full.nix
    ../modules/desktop/fcitx.nix
    # ../modules/desktop/i3/default.nix

    ../modules/programs/xrdp/default.nix
    # ../modules/programs/xrdp/gnome.nix
    ../modules/programs/xrdp/cosmic.nix
    # ../modules/programs/xrdp/kde.nix
    # ../modules/programs/xrdp/i3.nix

    ../modules/secure-boot.nix
    ../modules/documentation.nix
    ../modules/ssl-dev.nix
    ../modules/tailscale.nix
    ../modules/docker.nix

    ../modules/pipewire/crackle-fix.nix

    ../modules/amd.nix
    # ../modules/nvidia.nix
  ];

  boot.kernelModules = ["ntsync"];
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  # Disable other greeters since we can only have one.
  services.displayManager.gdm.enable = lib.mkForce false;
  # services.displayManager.cosmic-greeter.enable = lib.mkForce false;
  services.displayManager.sddm.enable = lib.mkForce false;

  services.flatpak.enable = true;

  services.tailscale.useRoutingFeatures = "client";

  my.vfio = {
    enable = true;
    amd.enable = true;
    amdgpu.enable = true;
  };

  my.rnnoise.micNodeName = "alsa_input.usb-HP__Inc_HyperX_SoloCast-00.iec958-stereo";

  environment.systemPackages = [
    pkgs.archipelago
    pkgs.flatpak
    pkgs.shipwright
    pkgs._2ship2harkinian
    pkgs.shipwright-ap
    pkgs.zelda64recomp
  ];
}
