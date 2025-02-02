{config, ...}: {
  boot.initrd.postMountCommands = ''
    ${config.boot.zfs.package}/bin/zfs rollback -r zroot/tmp@blank
  '';
}
