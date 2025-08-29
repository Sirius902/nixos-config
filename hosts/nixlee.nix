{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../modules/rollback-tmp.nix

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

  # TODO(Sirius902) LMAO. Remove this once the issue is fixed.
  # https://mundobytes.com/en/Linux-6%3A-16-problems-with-Asus-motherboards%3A-why-they-occur-and-how-to-mitigate-them-without-headaches/
  boot.blacklistedKernelModules = ["asus_wmi" "asus_nb_wmi"];

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  # Disable other greeters since we can only have one.
  services.displayManager.gdm.enable = lib.mkForce false;
  # services.displayManager.cosmic-greeter.enable = lib.mkForce false;
  services.displayManager.sddm.enable = lib.mkForce false;

  services.flatpak.enable = true;

  environment.systemPackages = [
    pkgs.archipelago
    pkgs.flatpak
    pkgs.shipwright
    pkgs._2ship2harkinian
    pkgs.shipwright-anchor
    pkgs.shipwright-ap
    pkgs.zelda64recomp
  ];

  my.rnnoise.micNodeName = "alsa_input.usb-HP__Inc_HyperX_SoloCast-00.iec958-stereo";
}
