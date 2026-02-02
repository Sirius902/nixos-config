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

    hostname = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
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
      };
    };

    systemd.services.svends = {
      description = "Sven Co-op Dedicated Server";
      after = ["network-online.target" "svends-updater.service"];
      wants = ["network-online.target"];

      serviceConfig = {
        User = "svends";
        Group = "svends";
        StateDirectory = "svends";
        WorkingDirectory = "/var/lib/svends";

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

        ExecStart = pkgs.writeShellScript "run-svends" ''
          ${pkgs.steam-run}/bin/steam-run ./svends_run \
            -console \
            -port ${toString cfg.port} \
            ${lib.optionalString cfg.insecure "-insecure"} \
            +maxplayers ${toString cfg.maxplayers} \
            +map ${cfg.map} \
            ${lib.optionalString (cfg.hostname != null) "+hostname \"${cfg.hostname}\""} \
            +log on
        '';

        Restart = "on-failure";
        RestartSec = "30s";
      };
    };
  };
}
