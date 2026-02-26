{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.desktop;
in {
  config = lib.mkIf (cfg.enable && cfg.environment == "i3") {
    # FUTURE(Sirius902) Fix i3.
    services.xserver = {
      enable = true;
      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [dmenu i3status];
      };
    };

    services.displayManager.cosmic-greeter.enable = lib.mkForce false;
    services.displayManager.gdm.enable = lib.mkForce false;
    services.displayManager.sddm.enable = lib.mkForce false;
  };
}
