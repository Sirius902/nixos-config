{lib, ...}: {
  imports = [
    ../modules/ssl-dev.nix
    ../modules/desktop-common.nix
  ];

  virtualisation.vmware.guest.enable = true;
}
