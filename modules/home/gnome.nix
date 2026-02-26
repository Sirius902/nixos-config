{
  lib,
  pkgs,
  ...
}: {
  dconf = let
    inherit (lib.hm.gvariant) mkTuple;
  in {
    enable = true;
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    settings."org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = with pkgs.gnomeExtensions; [
        appindicator.extensionUuid
      ];
    };
    settings."org/gnome/shell".favorite-apps = [
      "firefox.desktop"
      "com.mitchellh.ghostty.desktop"
      "code.desktop"
      "org.gnome.Nautilus.desktop"
      "discord-canary.desktop"
      "org.prismlauncher.PrismLauncher.desktop"
      "steam.desktop"
      "xivlauncher.desktop"
      "virt-manager.desktop"
    ];
    settings."org/gnome/desktop/interface".clock-format = "12h";
    settings."org/gtk/settings/file-chooser".clock-format = "12h";
    settings."org/gnome/mutter" = {
      edge-tiling = true;
      dynamic-workspaces = true;
      workspaces-only-on-primary = true;
    };
    settings."org/gnome/desktop/input-sources".sources = [(mkTuple ["xkb" "us"]) (mkTuple ["ibus" "mozc-on"])];
    settings."org/gnome/desktop/background" = {
      picture-uri = "file:///home/chris/Pictures/Backgrounds/Screenshot from 2024-07-07 23-23-16.png";
      picture-uri-dark = "file:///home/chris/Pictures/Backgrounds/Screenshot from 2024-07-07 23-23-16.png";
    };
    settings."org/gnome/settings-daemon/plugins/color".night-light-enabled = true;
  };

  home.packages = [
    pkgs.gnomeExtensions.appindicator
  ];
}
