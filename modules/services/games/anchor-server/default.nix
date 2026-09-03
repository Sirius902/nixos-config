# Anchor: the multiplayer sync server for Harbor Masters 64 ports.
#
# Modelled on ../svends/default.nix (socket + FIFO + ExecStop poll + hardening).
# The admin console (`list`, `messageAll`, `disableAll`, `deleteRoom`, `stop`)
# is driven through /run/anchor-server.stdin; all output goes to the journal.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.anchor-server;

  # Upstream hardcodes `net.Listen("tcp", ":43383")` — no flag, env var or
  # config file reaches it, so there is nothing for a `port` option to set.
  port = 43383;

  fifo = "/run/anchor-server.stdin";

  # Ported from ../minecraft-servers/default.nix. anchor is a static Go binary
  # (CGO_ENABLED=0), so it creates no namespaces and needs no secondary
  # personality: RestrictNamespaces and SystemCallArchitectures go all the way.
  hardening = {
    ProtectSystem = "strict";
    ReadWritePaths = [cfg.dataDir];

    CapabilityBoundingSet = [""];
    DeviceAllow = [""];
    LockPersonality = true;
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateTmp = true;
    # PrivateUsers is intentionally NOT enabled: dataDir is typically a
    # passthrough mount (virtiofs, ZFS) whose file ownership does not translate
    # into a user namespace, so the service would see stats.json as unowned.
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectProc = "invisible";
    RemoveIPC = true;
    RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
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
in {
  options.services.anchor-server = {
    enable = lib.mkEnableOption "the Anchor server";

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to start the server on boot (sets `wantedBy`). When false, the
        unit still exists and is started on demand with
        `systemctl start anchor-server` (which also brings up its FIFO socket).
      '';
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/anchor-server";
      description = ''
        Server working directory. The server reads `stats.json` and rewrites it
        relative to the CWD, every 30s and on shutdown.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the server's port in the firewall.";
    };

    hardening.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Apply the systemd sandboxing block (ProtectSystem, SystemCallFilter,
        CapabilityBoundingSet, …). Set false when the server runs inside a
        VM/microvm, where the hypervisor is the isolation boundary and the
        sandbox is just friction.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [port];
    };

    users.users.anchor-server = {
      description = "Anchor server service user";
      home = cfg.dataDir;
      createHome = true;
      homeMode = "0770";
      isSystemUser = true;
      group = "anchor-server";
    };

    users.groups.anchor-server = {};

    systemd.sockets.anchor-server = {
      bindsTo = ["anchor-server.service"];
      socketConfig = {
        ListenFIFO = fifo;
        SocketMode = "0660";
        SocketUser = "anchor-server";
        SocketGroup = "anchor-server";
        RemoveOnStop = true;
        FlushPending = true;
      };
    };

    systemd.services.anchor-server = {
      description = "Anchor server";
      wantedBy = lib.optionals cfg.autoStart ["multi-user.target"];
      requires = ["anchor-server.socket"];
      after = ["network.target" "anchor-server.socket"];

      serviceConfig =
        {
          User = "anchor-server";
          Group = "anchor-server";
          WorkingDirectory = cfg.dataDir;

          StandardInput = "socket";
          StandardOutput = "journal";
          StandardError = "journal";

          ExecStart = lib.getExe pkgs.anchor-server;

          # Stopped through the console rather than by signal: SIGTERM also
          # saves and exits cleanly, but first dumps every goroutine stack into
          # the journal.
          ExecStop = pkgs.writeShellScript "anchor-server-stop" ''
            echo stop > ${fifo}

            # Wait for the PID of the server to disappear before returning,
            # so systemd doesn't attempt to SIGKILL it.
            while kill -0 "$MAINPID" 2> /dev/null; do
              sleep 1s
            done
          '';

          Restart = "always";
          RestartSec = "10s";
        }
        // lib.optionalAttrs cfg.hardening.enable hardening;
    };
  };
}
