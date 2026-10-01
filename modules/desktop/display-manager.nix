{
  config,
  lib,
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
      services.displayManager.noctalia-greeter.enable = true;

      # noctalia-greeter discovers sessions from /run/current-system/sw/share.
      environment.pathsToLink = ["/share/wayland-sessions"];
    })
  ]);
}
