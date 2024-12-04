{
  lib,
  isDesktop,
  ...
}: {
  imports = [../modules/ssl-dev.nix] ++ (lib.lists.optional isDesktop ../modules/desktop-common.nix);

  virtualisation.vmware.guest.enable = true;
}
