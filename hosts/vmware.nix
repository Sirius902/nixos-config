{
  imports = [
    ../modules/desktop-common.nix
    ../modules/ssl-dev.nix
  ];

  virtualisation.vmware.guest.enable = true;
}
