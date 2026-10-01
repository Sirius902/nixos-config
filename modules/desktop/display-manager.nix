{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.desktop;
  dm = cfg.environment;
in {
  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services.displayManager.cosmic-greeter.enable = lib.mkForce (dm == "cosmic");
      services.displayManager.gdm.enable = lib.mkForce (dm == "gnome");
      services.displayManager.sddm.enable = lib.mkForce (dm == "kde");
    }
    (lib.mkIf (dm == "niri") {
      services.displayManager.noctalia-greeter = {
        enable = true;
        cursorTheme = {
          package = pkgs.pop-icon-theme;
          name = "Pop";
        };
        settings.cursor.size = 16;
        passwordlessSyncUsers = config.my.homeUsers;
      };
    })
  ]);
}
