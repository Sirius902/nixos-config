{
  config,
  lib,
  ...
}: let
  cfg = config.my.desktop;
in {
  config = lib.mkIf (cfg.enable && cfg.environment == "kde") {
    services.xserver.enable = true;

    services.desktopManager.plasma6.enable = true;

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    programs.kdeconnect.enable = lib.mkIf cfg.full true;
  };
}
