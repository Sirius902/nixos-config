{
  imports = [
    ../modules/desktop/default.nix
    ../modules/desktop/gnome/default.nix

    ../modules/ssl-dev.nix
  ];

  virtualisation.vmware.guest.enable = true;
}
