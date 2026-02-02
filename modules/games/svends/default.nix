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

    systemd.services.svends = {
      description = "Sven Co-op Dedicated Server";
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        DynamicUser = true;
        StateDirectory = "svends";
        WorkingDirectory = "/var/lib/svends";

        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;

        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        NoNewPrivileges = true;
        RestrictRealtime = true;

        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK"];

        SystemCallArchitectures = "native";

        # We block the following groups (~ means deny):
        # @clock: Setting system time
        # @module: Loading kernel drivers
        # @reboot: Rebooting/Powering off
        # @swap: Managing swap files
        # @cpu-emulation: vm86 (16-bit legacy support) - SAFE TO BLOCK for 32-bit apps
        # @obsolete: Old unused syscalls
        SystemCallFilter = ["~@clock" "~@module" "~@reboot" "~@swap" "~@cpu-emulation" "~@obsolete"];

        ExecStartPre = pkgs.writeShellScript "update-svends" ''
          ${pkgs.steamcmd}/bin/steamcmd \
            +@ShutdownOnFailedCommand 1 \
            +@NoPromptForPassword 1 \
            +force_install_dir ${config.systemd.services.svends.serviceConfig.WorkingDirectory} \
            +login anonymous \
            +app_update 276060 validate \
            +quit
        '';

        ExecStart = pkgs.writeShellScript "run-svends" ''
          ${pkgs.steam-run}/bin/steam-run ./svends_run \
            -console \
            -port ${toString cfg.port} \
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
