{
  imports = [
    ../modules/desktop/default.nix
    ../modules/desktop/gnome/default.nix
    ../modules/desktop/ibus.nix

    ../modules/ssl-dev.nix
  ];

  virtualisation.vmware.guest.enable = true;
}
