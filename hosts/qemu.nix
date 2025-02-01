{lib, ...}: {
  imports = [
    ../modules/desktop/default.nix
    ../modules/desktop/gnome/default.nix
  ];

  boot.zfs.devNodes = lib.mkForce "/dev/disk/by-partuuid";

  # TODO: We only need this on guests with a desktop environment.
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
}
