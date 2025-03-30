{pkgs, ...}: {
  # Autolaunch gcfeederd
  home.file.".config/autostart/gcfeederd.desktop".source = "${pkgs.gcfeederd}/share/applications/gcfeederd.desktop";
}
