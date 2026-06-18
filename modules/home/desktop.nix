{pkgs, ...}: {
  home.packages = [pkgs.smartmontools];

  dconf = {
    enable = true;
    settings."org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  gtk = {
    enable = true;
    # Workaround for KDE being annoying.
    gtk2.force = true;
    theme.name = "Adwaita-dark";
    gtk3.extraConfig."gtk-application-prefer-dark-theme" = 1;
  };
}
