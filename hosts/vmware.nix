{
  lib,
  isHeadless,
  ...
}: {
  imports = [../modules/ssl-dev.nix] ++ (lib.lists.optional (!isHeadless) ../modules/desktop-common.nix);

  virtualisation.vmware.guest.enable = true;
}
