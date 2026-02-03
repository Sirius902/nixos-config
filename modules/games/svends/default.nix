{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.games.svends;
in {
  options.my.games.svends = {
    enable = lib.mkEnableOption "svends";

    port = lib.mkOption {
      type = lib.types.port;
      default = 27015;
    };

    insecure = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    maxplayers = lib.mkOption {
      type = lib.types.int;
      default = 8;
    };

    map = lib.mkOption {
      type = lib.types.str;
      default = "_server_start";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = {
      allowedUDPPorts = [cfg.port 26900]; # Game traffic, VAC
      allowedTCPPorts = [cfg.port];
    };

    users.users.svends = {
      isSystemUser = true;
      group = "svends";
      home = "/var/lib/svends";
      createHome = true;
    };

    users.groups.svends = {};

    systemd.services.svends-updater = {
      description = "Update Sven Co-op Dedicated Server";
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "oneshot";

        User = "svends";
        Group = "svends";
        StateDirectory = "svends";
        WorkingDirectory = "/var/lib/svends";

        ProtectSystem = "strict";
        ReadWritePaths = ["/var/lib/svends"];

        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;

        ExecStart = pkgs.writeShellScript "update-svends" ''
          ${pkgs.steamcmd}/bin/steamcmd \
            +@ShutdownOnFailedCommand 1 \
            +@NoPromptForPassword 1 \
            +force_install_dir /var/lib/svends \
            +login anonymous \
            +app_update 276060 validate \
            +quit
        '';

        Restart = "on-failure";
        RestartSec = "5s";
        StartLimitBurst = 2;
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
      requires = ["svends.socket"];
      after = [
        "network.target"
        "svends-updater.service"
        "svends.socket"
      ];

      serviceConfig = {
        User = "svends";
        Group = "svends";
        StateDirectory = "svends";
        WorkingDirectory = "/var/lib/svends";

        CPUQuota = "200%";
        MemoryMax = "4G";
        TasksMax = 128;
        LimitNOFILE = 4096;

        ProtectSystem = "strict";
        ReadWritePaths = ["/var/lib/svends"];

        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;

        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        LockPersonality = true;
        NoNewPrivileges = true;
        RestrictRealtime = true;

        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK"];

        SystemCallFilter = ["~@clock" "~@module" "~@reboot" "~@swap" "~@cpu-emulation" "~@obsolete"];

        Sockets = "svends.socket";
        StandardInput = "socket";
        StandardOutput = "journal";
        StandardError = "journal";

        ExecStart = pkgs.writeShellScript "run-svends" ''
          ${pkgs.steam-run}/bin/steam-run ./svends_run \
            -console \
            -port ${toString cfg.port} \
            ${lib.optionalString cfg.insecure "-insecure"} \
            +maxplayers ${toString cfg.maxplayers} \
            +map ${cfg.map} \
            +log on
        '';

        Restart = "on-failure";
        RestartSec = "30s";
      };
    };
  };
}
