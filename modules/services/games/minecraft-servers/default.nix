# Generic, multi-instance Minecraft server framework.
#
# Each server runs as its own hardened systemd service `mc-<name>`, takes
# console input over a FIFO socket (`/run/mc-<name>.stdin`, drive it with
# `jscreen mc-<name>`) and logs to the journal. Backups are per-server ZFS
# snapshots via sanoid, flushed through the console before each snapshot.
#
# Modelled on ../svends/default.nix (socket + FIFO + ExecStop poll + hardening),
# generalised to multiple instances and to any modloader/vanilla via a
# per-server foreground `start.sh` entry point.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.minecraft-servers;

  # Resolve a server's JDK: its own `jdk`, else the host-wide `my.jdk`, else a
  # hard eval failure (we never silently fall back to some arbitrary JDK).
  serverJdk = name: s:
    if s.jdk != null
    then s.jdk
    else if config.my.jdk != null
    then config.my.jdk
    else throw "services.minecraft-servers.servers.${name}: no JDK selected — set its `jdk` option or the host-wide `my.jdk`.";

  fifo = name: "/run/mc-${name}.stdin";

  # The system's own ZFS userland, which is guaranteed to match the loaded
  # kernel module. Don't hardcode a path; take whatever the host is running.
  zfs = "${config.boot.zfs.package}/bin/zfs";
  systemctl = "${config.systemd.package}/bin/systemctl";

  serverOpts = {name, ...} @ args: let
    server = args.config;
  in {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to define units for this server.";
      };

      autoStart = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to start this server on boot (sets `wantedBy`). When false,
          the unit still exists and is started on demand with
          `systemctl start mc-<name>` (which also brings up its FIFO socket).
        '';
      };

      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "/media/data/mc/servers/${name}";
        description = "Server working directory (world, mods, configs, start.sh).";
      };

      jdk = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        defaultText = lib.literalExpression "config.my.jdk";
        description = ''
          JDK/JRE used to launch the server; placed on PATH for `start.sh`. MUST
          match the Minecraft version (1.12 -> 8, 1.20.x -> 17, 1.21 -> 21). When
          null it falls back to the host-wide `my.jdk`; if that is also null,
          evaluation fails — no JDK is ever chosen implicitly.
        '';
      };

      startScript = lib.mkOption {
        type = lib.types.str;
        default = "${server.dataDir}/start.sh";
        defaultText = lib.literalExpression ''"''${dataDir}/start.sh"'';
        description = ''
          Foreground entry point run as ExecStart. Must NOT use screen/`&`/a
          restart loop and should end in `exec java ... nogui` so the JVM is the
          main process (inherits the FIFO as stdin, receives SIGTERM).
        '';
      };

      extraJvmOpts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["-XX:+ExitOnOutOfMemoryError"];
        description = ''
          Extra JVM options injected ONLY into the systemd service (via
          JDK_JAVA_OPTIONS), on top of whatever start.sh passes to java. A manual
          `start.sh` run does not see these, so it stays clean. The default makes
          the JVM exit on OutOfMemoryError (incl. the GC-overhead-limit case) so
          systemd restarts it, instead of leaving a wedged-but-alive process.
        '';
      };

      stopCommand = lib.mkOption {
        type = lib.types.str;
        default = "stop";
        description = "Console command written to the FIFO to stop gracefully.";
      };

      stopTimeout = lib.mkOption {
        type = lib.types.str;
        default = "120s";
        description = "TimeoutStopSec; modded worlds can take a while to save.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 25565;
        description = "Primary port to open in the firewall (must match server.properties).";
      };

      extraPorts = {
        tcp = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [];
          description = "Additional TCP ports to open when openFirewall is set.";
        };
        udp = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [];
          description = "Additional UDP ports to open when openFirewall is set (e.g. voice chat).";
        };
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to open this server's ports in the firewall.";
      };

      memoryMax = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "12G";
        description = ''
          Hard cgroup memory ceiling for the WHOLE process (systemd MemoryMax) —
          NOT the JVM heap. This is deliberately not -Xmx: the JVM needs non-heap
          memory too (metaspace, thread stacks, GC structures, direct byte
          buffers, JIT code cache, mmap'd region files), so set this to the
          server's -Xmx plus ~4G of headroom (e.g. -Xmx8G -> "12G"). It is a
          runaway backstop the kernel OOM-kills the cgroup against, so it must sit
          above the real working set, never at it. null means no limit.

          (Named after the systemd directive, like cpuQuota/cpuWeight.)
        '';
      };

      cpuQuota = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "1400%";
        description = ''
          Optional CPUQuota hard cap (100% = one core). Unset means no cap, so the
          server bursts across all cores while cgroup fair-sharing still keeps it
          from starving other processes. Set e.g. "1400%" to always reserve cores
          for the rest of the system.
        '';
      };

      cpuWeight = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        example = 50;
        description = ''
          Optional CPUWeight (1-10000, default 100). Lower it (e.g. 50) to make the
          server yield to higher-weight processes (like an interactive desktop)
          under contention, while still bursting to free cores when they are idle.
        '';
      };

      zfsDataset = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "data/mc/atm10";
        description = "ZFS dataset backing dataDir; null disables ZFS snapshot backups.";
      };

      backup.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to schedule sanoid snapshots for this server (needs zfsDataset).";
      };

      serviceConfig = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Escape hatch merged last into serviceConfig (e.g. relax SystemCallFilter).";
      };
    };
  };

  enabledServers = lib.filterAttrs (_: s: s.enable) cfg.servers;
  backupServers = lib.filterAttrs (_: s: s.backup.enable && s.zfsDataset != null) enabledServers;

  # Hardening, ported from svends/synergyds + the upstream minecraft-server
  # module. Deliberately NO MemoryDenyWriteExecute (the JVM JIT needs W^X).
  hardening = dataDir: {
    ProtectSystem = "strict";
    ReadWritePaths = [dataDir];

    CapabilityBoundingSet = [""];
    DeviceAllow = [""];
    LockPersonality = true;
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateTmp = true;
    # PrivateUsers is intentionally NOT enabled: it runs the service in a user
    # namespace, but ZFS does not translate dataset file ownership into a userns,
    # so the service sees its own files (start.sh, the world) as unowned and gets
    # EACCES exec'ing/writing them. Re-add via serviceConfig on non-ZFS dataDirs.
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectProc = "invisible";
    RemoveIPC = true;
    RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
    # Deny all namespace creation. svends/synergyds must allow "user"+"mnt" for
    # steam-run (bwrap); a pure-Java server creates none, so match the stricter
    # upstream services.minecraft-server setting. systemd's own PrivateTmp/
    # PrivateDevices sandboxing is unaffected (set up by the manager, not us).
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
    SystemCallErrorNumber = "EPERM";
    SystemCallFilter = [
      "@system-service"
      "~@clock"
      "~@cpu-emulation"
      "~@debug"
      "~@module"
      "~@obsolete"
      "~@raw-io"
      "~@reboot"
      "~@swap"
    ];
    UMask = "0007";
  };

  mkSocket = name: _: {
    bindsTo = ["mc-${name}.service"];
    socketConfig = {
      ListenFIFO = fifo name;
      SocketMode = "0660";
      SocketUser = "mc-${name}";
      SocketGroup = "mc-${name}";
      RemoveOnStop = true;
      FlushPending = true;
    };
  };

  mkService = name: s: {
    description = "Minecraft server: ${name}";
    wantedBy = lib.optionals s.autoStart ["multi-user.target"];
    requires = ["mc-${name}.socket"];
    after = ["network.target" "mc-${name}.socket" "zfs-mount.service"];

    # dataDir often lives on a ZFS extra pool mounted late in boot; don't start
    # until it's actually mounted (matters for autoStart after a reboot).
    unitConfig.RequiresMountsFor = [s.dataDir];

    path = [(serverJdk name s)];

    environment = lib.optionalAttrs (s.extraJvmOpts != []) {
      JDK_JAVA_OPTIONS = lib.concatStringsSep " " s.extraJvmOpts;
    };

    startLimitIntervalSec = 300;
    startLimitBurst = 5;

    serviceConfig =
      {
        User = "mc-${name}";
        Group = "mc-${name}";
        WorkingDirectory = s.dataDir;

        StandardInput = "socket";
        StandardOutput = "journal";
        StandardError = "journal";

        TasksMax = 512;
        LimitNOFILE = 65536;

        # Never let the JVM heap (committed up-front by AlwaysPreTouch) be paged
        # to swap — a swapped heap is a GC-stall disaster. This keeps it resident;
        # it is complementary to ExitOnOutOfMemoryError (which handles -Xmx heap
        # exhaustion), NOT a trigger for it. MemoryMax stays the outer OOM cap.
        MemorySwapMax = 0;

        # Run start.sh via the system shell (absolute path) rather than exec'ing
        # it directly: the unit's PATH has the JRE but no shell, so a
        # `#!/usr/bin/env sh` shebang would fail with "env: 'sh': not found".
        # This also means start.sh need not be executable.
        ExecStart = "${pkgs.runtimeShell} ${s.startScript}";

        ExecStop = pkgs.writeShellScript "mc-${name}-stop" ''
          echo ${lib.escapeShellArg s.stopCommand} > ${fifo name}

          # Wait for the server PID to disappear before returning, so systemd
          # doesn't SIGKILL a still-saving world.
          while kill -0 "$MAINPID" 2> /dev/null; do
            sleep 1s
          done
        '';
        TimeoutStopSec = s.stopTimeout;

        Restart = "always";
        RestartSec = "10s";
        SuccessExitStatus = "0 130";
      }
      // (hardening s.dataDir)
      // lib.optionalAttrs (s.memoryMax != null) {MemoryMax = s.memoryMax;}
      // lib.optionalAttrs (s.cpuQuota != null) {CPUQuota = s.cpuQuota;}
      // lib.optionalAttrs (s.cpuWeight != null) {CPUWeight = s.cpuWeight;}
      // s.serviceConfig;
  };

  # sanoid pre-snapshot hook: skip if the server is off AND unchanged since the
  # last snapshot; flush the world (for a consistent snapshot) if it is running.
  mkPreScript = name: ds:
    pkgs.writeShellScript "mc-${name}-presnap" ''
      set -u
      unit="mc-${name}.service"
      pipe=${lib.escapeShellArg (fifo name)}

      if ! ${systemctl} is-active --quiet "$unit"; then
        written=$(${zfs} get -Hp -o value written ${lib.escapeShellArg ds})
        [ "$written" = "0" ] && exit 1   # off and unchanged -> skip this snapshot
        exit 0                           # off but changed -> snapshot on-disk state, no flush
      fi

      # Running: flush to disk so the snapshot is world-consistent.
      printf 'save-off\n'       > "$pipe"
      printf 'save-all flush\n' > "$pipe"
      sleep 3
      exit 0
    '';

  mkPostScript = name:
    pkgs.writeShellScript "mc-${name}-postsnap" ''
      unit="mc-${name}.service"
      pipe=${lib.escapeShellArg (fifo name)}
      if ${systemctl} is-active --quiet "$unit"; then
        printf 'save-on\n' > "$pipe"
      fi
      exit 0
    '';
in {
  options.services.minecraft-servers = {
    enable = lib.mkEnableOption "the Minecraft servers framework";

    admins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["chris"];
      description = ''
        Users added to every server's per-server group (`mc-<name>`). That lets
        them drive the console FIFO with `jscreen` and read/write the server's
        files directly (the data dir is setgid + group-writable). Each server
        keeps its OWN group, so admins can reach every server while the servers
        stay isolated from one another (one server's user cannot touch another's
        files). The server's own service user is the group's primary member.
      '';
    };

    servers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule serverOpts);
      default = {};
      description = "Minecraft server instances, keyed by name (unit = mc-<name>).";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      users.users = lib.mapAttrs' (name: s:
        lib.nameValuePair "mc-${name}" {
          description = "Minecraft server (${name}) service user";
          isSystemUser = true;
          group = "mc-${name}";
          home = s.dataDir;
        })
      enabledServers;

      # One group per server (admins joined in), used for both the data dir and
      # the console FIFO. Servers never share a group, so they cannot touch each
      # other's files; the service user is each group's primary member.
      users.groups = lib.mapAttrs' (name: _:
        lib.nameValuePair "mc-${name}" {members = cfg.admins;})
      enabledServers;

      systemd.services =
        lib.mapAttrs' (name: s: lib.nameValuePair "mc-${name}" (mkService name s)) enabledServers;

      systemd.sockets =
        lib.mapAttrs' (name: s: lib.nameValuePair "mc-${name}" (mkSocket name s)) enabledServers;

      networking.firewall.allowedTCPPorts =
        lib.concatMap (s: lib.optionals s.openFirewall ([s.port] ++ s.extraPorts.tcp))
        (lib.attrValues enabledServers);
      networking.firewall.allowedUDPPorts =
        lib.concatMap (s: lib.optionals s.openFirewall ([s.port] ++ s.extraPorts.udp))
        (lib.attrValues enabledServers);
    }

    (lib.mkIf (backupServers != {}) {
      services.sanoid = {
        enable = true;
        templates.minecraft = {
          # Disaster-recovery focus: fine-grained recent history + a trimmed tail.
          # (weekly/frequently are sanoid freeform; the rest are typed options.)
          frequently = 0;
          hourly = 48; # 2 days of hourly — the primary "catch it fast" window
          daily = 14; # 2 weeks
          weekly = 4; # ~1 month
          monthly = 3; # ~3 months tail; pinned (else sanoid's default keeps 6)
          yearly = 0;
          autosnap = true;
          autoprune = true;
          no_inconsistent_snapshot = true; # skip the snapshot if the pre script exits non-zero
          force_post_snapshot_script = true; # always re-enable saving
          script_timeout = 60;
        };
        datasets = lib.mapAttrs' (name: s:
          lib.nameValuePair s.zfsDataset {
            useTemplate = ["minecraft"];
            pre_snapshot_script = "${mkPreScript name s.zfsDataset}";
            post_snapshot_script = "${mkPostScript name}";
          })
        backupServers;
      };

      # sanoid runs as an unprivileged DynamicUser; add it to each backed-up
      # server's group so its pre/post hooks can write the group-owned FIFOs
      # (the world flush) for running servers.
      systemd.services.sanoid.serviceConfig.SupplementaryGroups =
        lib.mapAttrsToList (name: _: "mc-${name}") backupServers;
    })
  ]);
}
