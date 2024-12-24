{pkgs, ...}: {
  # NOTE(Sirius902) Make sure you're logged out of GNOME on the target machine otherwise
  # you'll arrive at a black screen.

  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "${pkgs.gnome-session}/bin/gnome-session";
  services.xrdp.openFirewall = true;
}
