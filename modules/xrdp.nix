{
  pkgs,
  desktopEnv,
  ...
}: {
  # NOTE(Sirius902) Make sure you're logged out of the desktop environment on the target
  # machine otherwise you'll arrive at a black screen.

  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager =
    {
      "gnome" = "${pkgs.gnome-session}/bin/gnome-session";
      "cosmic" = "${pkgs.cosmic-session}/bin/cosmic-session";
    }
    .${desktopEnv};
  services.xrdp.openFirewall = true;
}
