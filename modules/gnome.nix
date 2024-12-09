{
  pkgs,
  lib,
  isHeadless,
  isVm,
  ...
}:
lib.mkIf (!isHeadless) {
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [
      mozc
    ];
  };

  # Fix light text on light background using dark mode with ibus-mozc.
  environment.variables = {
    "GTK_IM_MODULE" = "ibus";
    "QT_IM_MODULE" = "ibus";
    "XMODIFIERS" = "@im=ibus";
    "MOZC_IBUS_CANDIDATE_WINDOW" = "ibus";
  };

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
