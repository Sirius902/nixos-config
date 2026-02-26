{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.desktop;
in {
  config = lib.mkIf (cfg.enable && cfg.environment == "gnome") {
    services.xserver.enable = true;

    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    services.displayManager.cosmic-greeter.enable = lib.mkForce false;
    services.displayManager.sddm.enable = lib.mkForce false;

    environment.gnome.excludePackages = [
      pkgs.gnome-tour
      pkgs.gnome-terminal
      pkgs.epiphany
      pkgs.geary
    ];

    environment.systemPackages = [
      pkgs.nautilus-python
    ];

    programs.kdeconnect = lib.mkIf cfg.full {
      enable = true;
      package = pkgs.gnomeExtensions.gsconnect;
    };

    home-manager.users.chris.imports = [
      ../../home/gnome.nix
      ../../home/ghostty/gnome.nix
    ];
  };
}
