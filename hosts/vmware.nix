{
  imports = [
    ../modules/desktop/default.nix
    # NOTE(Sirius902) GNOME seems to randomly locking up with graphics
    # acceleration enabled. Use COSMIC for now I guess. :)
    # ../modules/desktop/gnome/default.nix
    # ../modules/desktop/ibus.nix
    ../modules/desktop/cosmic/default.nix

    ../modules/ssl-dev.nix
  ];

  virtualisation.vmware.guest.enable = true;
}
