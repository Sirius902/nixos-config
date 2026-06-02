{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.desktop;
in {
  # NOTE: QDirStat registers as the only handler for inode/mount-point, so
  # `xdg-open` on mount points (e.g. /media/*) opens QDirStat instead of
  # COSMIC Files. Fix with:
  #   xdg-mime default com.system76.CosmicFiles.desktop inode/mount-point
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
