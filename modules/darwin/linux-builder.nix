{
  nix = {
    linux-builder = {
      enable = true;
      ephemeral = true;
      maxJobs = 2;
      config.virtualisation = {
        cores = 10;
        darwin-builder = {
          memorySize = 14 * 1024;
          diskSize = 64 * 1024;
        };
        # TODO(Sirius902) Drop once nixpkgs stops pinning the darwin entry of
        # `nixos/lib/qemu-common.nix` to `gic-version=2`, which qemu's
        # virt-11.1 machine rejects under hvf's GICv3-only in-kernel vGIC.
        # https://github.com/qemu/qemu/commit/37863fff59e0b2c71989f2de906a52935f11ce7b
        qemu.options = ["-machine gic-version=max"];
      };
    };
    # NOTE(Sirius902) Required for linux-builder
    settings.trusted-users = ["@admin"];
  };
}
