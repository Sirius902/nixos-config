{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.boot.zfs.enabled (lib.mkMerge [
    {
      # Upstream ships /dev/zfs at 0666, and the ioctl path unpacks the caller's
      # nvlist before it checks authorization. Group-gate the device permanently;
      # 2.4.4 fixed the capability checks, not the mode.
      users.groups.zfs-admin = {};

      # static_node repeated deliberately: udevd's startup pass only honours perms on
      # the same rule line, so without it any udevd restart — NixOS does one per
      # rules change — restores 0666.
      services.udev.extraRules = ''
        KERNEL=="zfs", OWNER:="root", GROUP:="zfs-admin", MODE:="0660", OPTIONS+="static_node=zfs"
      '';
    }

    (lib.mkIf config.services.sanoid.enable {
      # sanoid snapshots as an unprivileged DynamicUser, so it needs the device;
      # deny it namespaces so that access can't become pool-wide authority.
      systemd.services.sanoid.serviceConfig = {
        SupplementaryGroups = ["zfs-admin"];
        RestrictNamespaces = "~user";
      };
    })
  ]);
}
