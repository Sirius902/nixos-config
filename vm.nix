{
  # TODO: Move this to configuration.nix if it turns out non-VMs require this to boot.
  #boot.zfs.devNodes = "/dev/disk/by-partuuid";

  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
}
