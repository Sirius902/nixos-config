{
  config,
  lib,
  ...
}: let
  cfg = config.my.desktop;
in {
  config = lib.mkIf (cfg.enable && cfg.environment == "kde") {
    services.xserver.enable = true;

    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;

    services.displayManager.cosmic-greeter.enable = lib.mkForce false;
    services.displayManager.gdm.enable = lib.mkForce false;

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    programs.kdeconnect.enable = lib.mkIf cfg.full true;
  };
}
