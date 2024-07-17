{ lib, ... }:

{
  imports = [ ];

  boot.zfs.devNodes = lib.mkForce "/dev/disk/by-partuuid";

  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
}
