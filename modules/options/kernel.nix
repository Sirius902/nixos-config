{lib, ...}: {
  options.my.kernelPatches = with lib;
    mkOption {
      type = types.listOf types.path;
      default = [];
      description = "Patches to apply to the Linux kernel.";
    };
}
