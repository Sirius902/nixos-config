{pkgs, ...}: {
  # NOTE(Sirius902) Make sure you're logged out of the desktop environment on the target
  # machine otherwise you'll arrive at a black screen.

  services.xrdp.enable = true;
  # TODO(Sirius902) GNOME only.
  services.xrdp.defaultWindowManager = "${pkgs.gnome-session}/bin/gnome-session";
  services.xrdp.openFirewall = true;
}
