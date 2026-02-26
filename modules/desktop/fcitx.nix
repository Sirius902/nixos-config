{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.desktop;
in {
  config = lib.mkIf (cfg.enable && cfg.inputMethod == "fcitx") {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        addons = [
          pkgs.fcitx5-mozc
          pkgs.fcitx5-gtk
        ];
        waylandFrontend = true;
      };
    };
  };
}
