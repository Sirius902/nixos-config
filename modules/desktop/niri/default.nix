{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.desktop;
in {
  config = lib.mkIf cfg.enable {
    programs.niri = {
      enable = true;
      useNautilus = false;
    };

    xdg.portal = {
      extraPortals = [pkgs.xdg-desktop-portal-cosmic];
      config.niri."org.freedesktop.impl.portal.FileChooser" = lib.mkForce "cosmic";
    };

    programs.noctalia = {
      enable = true;
      recommendedServices.enable = true;
    };

    services.gvfs.enable = true;
    services.avahi.enable = lib.mkDefault true;

    environment.systemPackages = with pkgs; [
      cosmic-files
      cosmic-icons
      cosmic-monitor
      fuzzel
      xwayland-satellite
    ];

    home-manager.users = lib.genAttrs config.my.homeUsers (_: {
      imports = [
        ../../home/cursor.nix
        ../../home/niri.nix
      ];
    });
  };
}
