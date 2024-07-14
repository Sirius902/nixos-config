{
  boot.zfs.devNodes = "/dev/disk/by-partlabel/disk-vda-zfs";

  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
}
