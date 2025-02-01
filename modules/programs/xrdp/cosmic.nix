{pkgs, ...}: {
  services.xrdp.defaultWindowManager = "${pkgs.cosmic-session}/bin/cosmic-session";
}
