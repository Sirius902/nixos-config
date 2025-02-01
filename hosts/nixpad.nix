{
  imports = [
    ../modules/desktop/full.nix
    ../modules/desktop/gnome/full.nix

    ../modules/secure-boot.nix
  ];

  # Disable wireplumber keeping cameras open wasting battery.
  services.pipewire.wireplumber.extraConfig = {
    "disable-camera" = {
      "monitor.libcamera" = "disabled";
    };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;
}
