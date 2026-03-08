{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.synergyds;
in {
  options.services.synergyds = {
    enable = lib.mkEnableOption "synergyds";

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
      default = "d1_trainstation_01";
      description = "Starting map for the server.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/synergyds";
      description = ''
        Directory to store Synergy state/data files.
      '';
    };

    extraCommandLine = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Extra command-line arguments to pass to srcds_linux.
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

    users.users.synergyds = {
      description = "Synergy server service user";
      home = cfg.dataDir;
      createHome = true;
      isSystemUser = true;
      group = "synergyds";
    };

    users.groups.synergyds = {};

    systemd.services.synergyds-update = {
      description = "Update Synergy Dedicated Server";
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "oneshot";

        User = "synergyds";
        Group = "synergyds";
        WorkingDirectory = cfg.dataDir;

        # TODO(Sirius902) This isn't going to work, we need to be auth'd as my
        # Steam account to download the games.
        ExecStart = pkgs.writeShellScript "synergyds-update-start" ''
          ${pkgs.steamcmd}/bin/steamcmd \
            +@ShutdownOnFailedCommand 1 \
            +@NoPromptForPassword 1 \
            +force_install_dir ${cfg.dataDir} \
            +login anonymous \
            +app_update 220 \
            +app_update 420 \
            +app_update 380 \
            +app_update 17520 validate \
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
        UMask = "0077";
      };
    };

    systemd.services.synergyds = {
      description = "Synergy Dedicated Server";
      wantedBy = ["multi-user.target"];
      after = [
        "network.target"
        "synergyds-update.service"
      ];

      serviceConfig = {
        User = "synergyds";
        Group = "synergyds";
        WorkingDirectory = cfg.dataDir;

        # srcds_linux requires an executable stack; glibc >= 2.39 disallows
        # this by default, so we must opt back in via GLIBC_TUNABLES.
        Environment = "GLIBC_TUNABLES=glibc.rtld.execstack=2";

        RuntimeDirectory = "synergyds";
        RuntimeDirectoryMode = "0750";

        CPUQuota = "200%";
        MemoryMax = "4G";
        TasksMax = 128;
        LimitNOFILE = 4096;

        # TODO(Sirius902) Idk if we still need this.
        ExecStartPre = pkgs.writeShellScript "synergyds-prestart" ''
          mkdir -p ${cfg.dataDir}/.steam/sdk32
          ln -sf ${cfg.dataDir}/.local/share/Steam/linux32/steamclient.so ${cfg.dataDir}/.steam/sdk32/steamclient.so
        '';

        ExecStart = let
          # TODO(Sirius902) Force insecure when preloading stuff like this?
          serverScript = pkgs.writeShellScript "synergyds-server" ''
            cd ${cfg.dataDir}/.steam/root/Steamapps/common/Synergy
            ${pkgs.steam-run}/bin/steam-run env \
              LD_PRELOAD="${cfg.dataDir}/libsynergy_abh.so" \
              LD_LIBRARY_PATH=".:bin:$LD_LIBRARY_PATH" \
              ./srcds_linux \
                -console \
                -game synergy \
                -port ${toString cfg.port} \
                ${lib.optionalString cfg.insecure "-insecure"} \
                +maxplayers ${toString cfg.maxplayers} \
                +map ${lib.escapeShellArg cfg.map} \
                +log on \
                ${lib.optionalString (cfg.extraCommandLine != "") (lib.escapeShellArg cfg.extraCommandLine)}
          '';
        in
          pkgs.writeShellScript "synergyds-start" ''
            SOCKET="/run/synergyds/tmux.sock"
            SHELL=${pkgs.bash}/bin/bash ${pkgs.tmux}/bin/tmux -S "$SOCKET" new-session -d -s synergyds \
              "${serverScript}; ${pkgs.tmux}/bin/tmux -S $SOCKET wait-for -S synergyds-done"
            chmod 0660 "$SOCKET"

            ${pkgs.tmux}/bin/tmux -S "$SOCKET" pipe-pane -t synergyds "exec ${pkgs.systemd}/bin/systemd-cat -t synergyds"

            ${pkgs.tmux}/bin/tmux -S "$SOCKET" wait-for synergyds-done
          '';

        ExecStop = pkgs.writeShellScript "synergyds-stop" ''
          ${pkgs.tmux}/bin/tmux -S /run/synergyds/tmux.sock send-keys -t synergyds "quit" Enter || true
          ${pkgs.tmux}/bin/tmux -S /run/synergyds/tmux.sock wait-for synergyds-done
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
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
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
        UMask = "0077";
      };
    };
  };
}
