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

    # FUTURE(Sirius902) Niri's Mutter ScreenCast PipeWire stream doesn't
    # offer SHM fallback formats, breaking Discord/Electron screen sharing.
    # Route ScreenCast through the wlr portal which handles this correctly.
    # Remove when niri-wm/niri#455 is fixed.
    xdg.portal = {
      extraPortals = [pkgs.xdg-desktop-portal-wlr];
      config.niri = {
        "org.freedesktop.impl.portal.ScreenCast" = lib.mkForce "wlr";
        "org.freedesktop.impl.portal.Screenshot" = lib.mkForce "wlr";
      };
    };

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
