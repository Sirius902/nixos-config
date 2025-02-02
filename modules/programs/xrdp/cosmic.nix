{pkgs, ...}: {
  # FUTURE(Sirius902) This doesn't seem to work.
  services.xrdp.defaultWindowManager = "${pkgs.cosmic-session}/bin/cosmic-session";
}
