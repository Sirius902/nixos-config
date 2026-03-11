{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.svends;
in {
  options.services.svends = {
    enable = lib.mkEnableOption "svends";

    port = lib.mkOption {
      type = lib.types.port;
      default = 27015;
      description = "Port number for the server to listen on.";
    };

    insecure = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to disable VAC (Valve Anti-Cheat).";
    };

    maxplayers = lib.mkOption {
      type = lib.types.ints.positive;
      default = 8;
      description = "Maximum number of players allowed on the server.";
    };

    map = lib.mkOption {
      type = lib.types.str;
      default = "_server_start";
      description = "Starting map for the server.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/svends";
      description = ''
        Directory to store Sven Co-op state/data files.
      '';
    };

    extraCommandLine = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Extra command-line arguments to pass to svends_run.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to open ports in the firewall for the server.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedUDPPorts = [cfg.port] ++ lib.optional (!cfg.insecure) 26900; # Game traffic, VAC
      allowedTCPPorts = [cfg.port];
    };

    users.users.svends = {
      description = "Sven Co-op server service user";
      home = cfg.dataDir;
      createHome = true;
      homeMode = "0770";
      isSystemUser = true;
      group = "svends";
    };

    users.groups.svends = {};

    systemd.services.svends-update = {
      description = "Update Sven Co-op Dedicated Server";
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "oneshot";

        User = "svends";
        Group = "svends";
        WorkingDirectory = cfg.dataDir;

        ExecStart = pkgs.writeShellScript "svends-update-start" ''
          ${pkgs.steamcmd}/bin/steamcmd \
            +@ShutdownOnFailedCommand 1 \
            +@NoPromptForPassword 1 \
            +force_install_dir ${cfg.dataDir} \
            +login anonymous \
            +app_update 276060 validate \
            +quit
        '';

        Restart = "on-failure";
        RestartSec = "5s";
        StartLimitBurst = 2;

        # Hardening
        ProtectSystem = "strict";
        ReadWritePaths = [cfg.dataDir];
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;

        CapabilityBoundingSet = [""];
        LockPersonality = true;
        NoNewPrivileges = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
        RestrictNamespaces = ["user" "mnt"];
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = ["native" "x86"];
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = [
          "@system-service"
          "@mount"
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
    };

    systemd.sockets.svends = {
      bindsTo = ["svends.service"];
      socketConfig = {
        ListenFIFO = "/run/svends.stdin";
        SocketMode = "0660";
        SocketUser = "svends";
        SocketGroup = "svends";
        RemoveOnStop = true;
        FlushPending = true;
      };
    };

    systemd.services.svends = {
      description = "Sven Co-op Dedicated Server";
      wantedBy = ["multi-user.target"];
      requires = ["svends.socket"];
      after = [
        "network.target"
        "svends.socket"
        "svends-update.service"
      ];

      serviceConfig = {
        User = "svends";
        Group = "svends";
        WorkingDirectory = cfg.dataDir;

        StandardInput = "socket";
        StandardOutput = "journal";
        StandardError = "journal";

        CPUQuota = "200%";
        MemoryMax = "4G";
        TasksMax = 128;
        LimitNOFILE = 4096;

        ExecStart = pkgs.writeShellScript "svends-start" ''
          ${pkgs.steam-run}/bin/steam-run ./svends_run \
            -console \
            -port ${toString cfg.port} \
            ${lib.optionalString cfg.insecure "-insecure"} \
            +maxplayers ${toString cfg.maxplayers} \
            +map ${lib.escapeShellArg cfg.map} \
            +log on \
            ${lib.optionalString (cfg.extraCommandLine != "") (lib.escapeShellArg cfg.extraCommandLine)}
        '';

        ExecStop = pkgs.writeShellScript "svends-stop" ''
          echo quit > ${config.systemd.sockets.svends.socketConfig.ListenFIFO}

          # Wait for the PID of the server to disappear before returning,
          # so systemd doesn't attempt to SIGKILL it.
          while kill -0 "$MAINPID" 2> /dev/null; do
            sleep 1s
          done
        '';

        Restart = "always";
        SuccessExitStatus = "0 130";

        # Hardening
        ProtectSystem = "strict";
        ReadWritePaths = [cfg.dataDir];

        CapabilityBoundingSet = [""];
        DeviceAllow = [""];
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
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
        RestrictNamespaces = ["user" "mnt"];
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = ["native" "x86"];
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = [
          "@system-service"
          "@mount"
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
    };
  };
}
