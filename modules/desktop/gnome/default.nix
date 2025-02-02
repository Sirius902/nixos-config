{pkgs, ...}: {
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = [
    pkgs.gnome-tour
    pkgs.gnome-terminal # Console
    pkgs.epiphany # Web Browser
    pkgs.geary # Email Viewer
  ];
}
