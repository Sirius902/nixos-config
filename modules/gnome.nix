{
  pkgs,
  lib,
  isHeadless,
  isVm,
  desktopEnv,
  ...
}:
lib.mkIf (desktopEnv == "gnome" && !isHeadless) {
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-terminal # Console
    epiphany # Web Browser
    geary # Email Viewer
  ];

  programs.kdeconnect = lib.mkIf (!isVm) {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };
}
