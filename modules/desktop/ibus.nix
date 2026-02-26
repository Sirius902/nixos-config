{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.desktop;
in {
  config = lib.mkIf (cfg.enable && cfg.inputMethod == "ibus") {
    i18n.inputMethod = {
      enable = true;
      type = "ibus";
      ibus.engines = with pkgs.ibus-engines; [
        mozc
      ];
    };

    # Fix light text on light background using dark mode with ibus-mozc.
    environment.variables = {
      "GTK_IM_MODULE" = "ibus";
      "QT_IM_MODULE" = "ibus";
      "XMODIFIERS" = "@im=ibus";
      "MOZC_IBUS_CANDIDATE_WINDOW" = "ibus";
    };
  };
}
