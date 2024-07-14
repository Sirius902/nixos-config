# https://github.com/nix-community/disko
# sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./disk-config.nix

{
  disko.devices = {
    disk = {
      # TODO: Customize disk based on gitignore'd config.
      vda = {
        type = "disk";
        device = "/dev/vda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "512M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/efi";
              };
            };
            swap = {
              size = "4G";
              content.type = "swap";
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zpool";
              };
            };
          };
        };
      };
    };
    # NOTE: Use legacy mountpoints to prevent a race condition when importing pools during boot.
    # If not using legacy mountpoints both systemd and zfs will attempt to import them.
    zpool = {
      zpool = {
        type = "zpool";
        rootFsOptions = {
          acltype = "posixacl";
          compression = "on";
          xattr = "sa";
          mountpoint = "none";
        };
        options.ashift = "12";
        # TODO: Consider adding 10G reserved dataset to prevent performance deterioration.
        # https://nixos.wiki/wiki/ZFS#Mount_datasets_at_boot

        datasets = {
          root = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
            postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zpool/root@blank$' || zfs snapshot zpool/root@blank";
          };
          nix = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              atime = "off";
              mountpoint = "legacy";
            };
          };
          persist = {
            type = "zfs_fs";
            mountpoint = "/persist";
            options.mountpoint = "legacy";
          };
          home = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "legacy";
            postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zpool/home@blank$' || zfs snapshot zpool/home@blank";
          };
        };
      };
    };
  };
}
