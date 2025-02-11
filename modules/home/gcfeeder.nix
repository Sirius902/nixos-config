{pkgs, ...}: {
  # Autolaunch gcfeeder
  home.file.".config/autostart/gcfeeder.desktop".source = "${pkgs.gcfeeder}/share/applications/gcfeeder.desktop";
}
