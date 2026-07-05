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

    security.pam.services.swaylock = {};

    environment.systemPackages = with pkgs; [
      fuzzel
      mako
      playerctl
      swaybg
      sunsetr
      swayidle
      swaylock-effects
      waybar
      xwayland-satellite
    ];

    home-manager.users.chris.imports = [
      ../../home/cosmic.nix
      ../../home/niri.nix
    ];
  };
}
