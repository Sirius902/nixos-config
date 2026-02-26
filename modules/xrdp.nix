{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.xrdp;
in {
  options.my.xrdp.enable = lib.mkEnableOption "xrdp";

  # NOTE(Sirius902) Make sure you're logged out of the desktop environment on the target
  # machine otherwise you'll arrive at a black screen.
  config = lib.mkIf cfg.enable {
    services.xrdp = {
      enable = true;
      openFirewall = true;
      defaultWindowManager =
        {
          "cosmic" = "${pkgs.cosmic-session}/bin/cosmic-session";
          "gnome" = "${pkgs.gnome-session}/bin/gnome-session";
          "kde" = "${pkgs.kdePackages.plasma-workspace}/bin/startplasma-x11";
          "i3" = "i3";
        }
        .${
          config.my.desktop.environment
        };
    };
  };
}
