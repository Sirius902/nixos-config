# Shared memory profile: compressed-RAM swap (zram) in place of disk swap, a
# swappiness tuned for in-memory swap, and an optional ZFS ARC cap.
#
# Inert until a host sets `my.memory.enable = true` (same pattern as my.jdk).
# Declare the host's RAM with `my.memory.ramGiB` and the rest is derived; every
# derived value is still individually overridable.
#
# Rationale (verified against kernel/OpenZFS/systemd docs, 2026):
#  - zram replaces disk swap entirely on hosts that don't hibernate (Fedora's
#    default since F33): no SSD/SD wear, no swap I/O latency, and it sidesteps
#    the swap-on-zvol deadlock risk on ZFS hosts.
#  - vm.swappiness: the kernel treats 100 as "swap and fs paging cost the same"
#    and accepts up to 200. For swap N x faster than filesystem paging its own
#    formula gives swappiness = 200*N/(N+1); zram is RAM-speed, so 133 (the "2x
#    faster" reference) is a floor for any zram host, and tiny boxes (usually
#    paired with slow storage) lean higher.
#  - ZFS ARC defaults (zfs_arc_max=0) to ~(RAM - 1 GiB) on modern OpenZFS, not
#    50%, so on a RAM-contended ZFS host cap it explicitly. Only ZFS hosts are
#    capped (auto-detected via boot.zfs.enabled); non-ZFS hosts get no line.
{
  config,
  lib,
  ...
}: let
  cfg = config.my.memory;
  ram = cfg.ramGiB;

  # zram logical size as % of RAM. Tiny boxes effectively live in swap, so they
  # get a device larger than RAM (compression makes the physical cost a
  # fraction); roomy boxes rarely swap and need only a small overflow.
  zramPercentFor =
    if ram == null
    then 50
    else if ram <= 2
    then 150
    else if ram <= 4
    then 100
    else if ram <= 16
    then 50
    else if ram <= 48
    then 33
    else 25;

  # 133 is the kernel's reference for swap ~2x faster than fs paging; zram beats
  # that, so it is a floor. <=2 GiB boxes usually pair with slow storage (SD),
  # where zram is many times faster -> bias harder into it.
  swappinessFor =
    if ram != null && ram <= 2
    then 150
    else 133;

  # Only cap ARC on actual ZFS hosts (never the F2FS Pi). Default to 3/8 of RAM
  # (~37.5%): leaves the majority for applications, sane for workstations and
  # app-servers. Override UP on a dedicated fileserver, DOWN on a host with a
  # large fixed workload (e.g. the Minecraft JVM server).
  arcMaxGiBFor =
    if config.boot.zfs.enabled && ram != null
    then lib.max 1 (ram * 3 / 8) # floor at 1 GiB so a tiny ZFS host can't yield 0
    else null;
in {
  options.my.memory = {
    enable = lib.mkEnableOption "the zram swap + swappiness (+ optional ZFS ARC cap) profile";

    ramGiB = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      example = 32;
      description = ''
        Physical RAM of this machine, in GiB. It cannot be detected at
        evaluation time (the config may be built on another host), so declare it
        here. When set it drives the defaults for zramPercent, swappiness and
        (on ZFS hosts) arcMaxGiB — each of which can still be overridden.
      '';
    };

    zramPercent = lib.mkOption {
      type = lib.types.ints.positive;
      default = zramPercentFor;
      defaultText = lib.literalMD "derived from `ramGiB` (150 if ≤2 GiB … 25 if >48 GiB; 50 if `ramGiB` unset)";
      description = ''
        zram device size as a percentage of RAM — its logical (uncompressed)
        capacity; physical use is far smaller thanks to compression. May exceed
        100 on tiny-RAM hosts.
      '';
    };

    zramAlgorithm = lib.mkOption {
      type = lib.types.str;
      default = "zstd";
      example = "lz4";
      description = ''
        zram compression algorithm. zstd gives the best ratio and is the right
        default on capable x86 cores; lz4 / lzo-rle cost far less CPU and are
        preferable on weak cores (e.g. a Raspberry Pi) where compression latency
        matters more than ratio. (A CPU choice, not a RAM one, so not derived.)
      '';
    };

    swappiness = lib.mkOption {
      type = lib.types.ints.between 0 200;
      default = swappinessFor;
      defaultText = lib.literalMD "derived from `ramGiB` (150 if ≤2 GiB, else 133)";
      description = ''
        vm.swappiness. 133 is the kernel's reference for swap ~2x faster than
        filesystem paging — a sound floor for any zram host; ≤2 GiB hosts lean to
        150 (tiny RAM, usually slow backing store).
      '';
    };

    arcMaxGiB = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = arcMaxGiBFor;
      defaultText = lib.literalMD "on ZFS hosts `ramGiB * 3 / 8`; `null` (no cap) on non-ZFS hosts";
      description = ''
        Hard-cap the ZFS ARC at this many GiB via modprobe. Auto-defaults to 3/8
        of RAM on ZFS hosts and null (no cap line) on non-ZFS hosts. Modern
        OpenZFS otherwise defaults zfs_arc_max=0 to ~(RAM - 1 GiB), i.e. nearly
        all RAM. Override UP for a fileserver, DOWN for a host with a big fixed
        workload (e.g. 8 on the 32 GiB Minecraft server to clear the 12 GiB JVM
        cgroup).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    warnings =
      lib.optional (cfg.ramGiB == null)
      "my.memory.enable is set but my.memory.ramGiB is unset; using generic fallback defaults (zram 50%, swappiness 133, no ARC cap). Set ramGiB for RAM-tuned defaults.";

    zramSwap = {
      enable = true;
      algorithm = cfg.zramAlgorithm;
      memoryPercent = cfg.zramPercent;
    };

    boot.kernel.sysctl."vm.swappiness" = cfg.swappiness;

    boot.extraModprobeConfig =
      lib.mkIf (cfg.arcMaxGiB != null)
      "options zfs zfs_arc_max=${toString (cfg.arcMaxGiB * 1024 * 1024 * 1024)}";
  };
}
