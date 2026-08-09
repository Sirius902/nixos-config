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
      services.greetd = {
        enable = true;
        settings.default_session = {
          command = lib.getExe pkgs.noctalia-greeter;
          user = "greeter";
        };
      };

      services.accounts-daemon.enable = true;

      # noctalia-greeter discovers sessions from /run/current-system/sw/share.
      environment.pathsToLink = ["/share/wayland-sessions"];

      systemd.tmpfiles.settings."10-noctalia-greeter"."/var/lib/noctalia-greeter".d = {
        user = "greeter";
        group = "greeter";
        mode = "0750";
      };
    })
  ]);
}
