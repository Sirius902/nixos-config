{lib, ...}: {
  imports = [../modules/desktop-common.nix];

  boot.zfs.devNodes = lib.mkForce "/dev/disk/by-partuuid";

  # TODO: We only need this on guests with a desktop environment.
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
}
