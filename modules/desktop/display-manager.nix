{
  config,
  lib,
  ...
}: let
  cfg = config.my.desktop;
  dm = cfg.environment;
in {
  config = lib.mkIf cfg.enable {
    services.displayManager.cosmic-greeter.enable = lib.mkForce (dm == "cosmic");
    services.displayManager.gdm.enable = lib.mkForce (dm == "gnome");
    services.displayManager.sddm.enable = lib.mkForce (dm == "kde");
  };
}
