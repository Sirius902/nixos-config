{pkgs, ...}: {
  services.xrdp.defaultWindowManager = "${pkgs.gnome-session}/bin/gnome-session";
}
