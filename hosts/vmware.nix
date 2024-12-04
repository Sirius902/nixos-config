{
  lib,
  isDesktop,
  ...
}: {
  imports = lib.lists.optional isDesktop ../modules/desktop-common.nix;

  virtualisation.vmware.guest.enable = true;
}
