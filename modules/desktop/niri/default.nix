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

    security.pam.services.hyprlock = {};

    environment.systemPackages = with pkgs; [
      fuzzel
      mako
      playerctl
      swaybg
      sunsetr
      swayidle
      hyprlock
      waybar
      xwayland-satellite
    ];

    home-manager.users.chris.imports = [
      ../../home/cosmic.nix
      ../../home/niri.nix
    ];
  };
}
