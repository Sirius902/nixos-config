# Synergy dedicated server for a microVM guest (modules/microvms). Nothing
# updates it: downloading Synergy takes the owner's Steam login. `vm console`
# reaches its console, and all output goes to the journal.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.synergyds;

  fifo = "/run/synergyds.stdin";
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
      default = config.my.vm.dataPath;
      defaultText = lib.literalExpression "config.my.vm.dataPath";
      description = ''
        The service user's home, holding the Steam install with Synergy.
      '';
    };

    extraCommandLine = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Extra command-line arguments to pass to srcds_linux.
      '';
    };

    extraCommandLineFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        File with extra command-line arguments to pass to srcds_linux,
        read at service start so the contents stay out of the Nix store.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.synergyds = {
      description = "Synergy server service user";
      home = cfg.dataDir;
      isSystemUser = true;
      group = "synergyds";
    };

    users.groups.synergyds = {};

    systemd.sockets.synergyds = {
      bindsTo = ["synergyds.service"];
      socketConfig = {
        ListenFIFO = fifo;
        SocketMode = "0660";
        SocketUser = "synergyds";
        SocketGroup = "synergyds";
        RemoveOnStop = true;
        FlushPending = true;
      };
    };

    systemd.services.synergyds = {
      description = "Synergy Dedicated Server";
      wantedBy = ["multi-user.target"];
      requires = ["synergyds.socket"];
      after = [
        "network.target"
        "synergyds.socket"
      ];
      unitConfig.RequiresMountsFor = [cfg.dataDir] ++ lib.optional (cfg.extraCommandLineFile != null) cfg.extraCommandLineFile;

      serviceConfig = {
        User = "synergyds";
        Group = "synergyds";
        WorkingDirectory = cfg.dataDir;

        LoadCredential = lib.mkIf (cfg.extraCommandLineFile != null) [
          "extra-command-line:${cfg.extraCommandLineFile}"
        ];

        # srcds_linux requires an executable stack; glibc >= 2.39 disallows
        # this by default, so we must opt back in via GLIBC_TUNABLES.
        Environment = "GLIBC_TUNABLES=glibc.rtld.execstack=2";

        StandardInput = "socket";
        StandardOutput = "journal";
        StandardError = "journal";

        TasksMax = 128;
        LimitNOFILE = 4096;

        # TODO(Sirius902) Idk if we still need this.
        ExecStartPre = pkgs.writeShellScript "synergyds-prestart" ''
          mkdir -p ${cfg.dataDir}/.steam/sdk32
          ln -sf ${cfg.dataDir}/.local/share/Steam/linux32/steamclient.so ${cfg.dataDir}/.steam/sdk32/steamclient.so
        '';

        # NOTE(Sirius902) script(1) allocates a PTY so srcds_linux sees a real
        # terminal and uses stdin/stdout as normal.
        ExecStart = let
          # TODO(Sirius902) Force insecure when preloading stuff like this?
          srcdsScript = pkgs.writeShellScript "synergyds-srcds" ''
            LD_PRELOAD="${cfg.dataDir}/libsynergy_abh.so" LD_LIBRARY_PATH=".:bin:$LD_LIBRARY_PATH" ./srcds_linux \
              -console \
              -game synergy \
              -port ${toString cfg.port} \
              ${lib.optionalString cfg.insecure "-insecure"} \
              +maxplayers ${toString cfg.maxplayers} \
              +map ${lib.escapeShellArg cfg.map} \
              +log on \
              ''${SRCDS_EXTRA_ARGS:+"$SRCDS_EXTRA_ARGS"}
          '';
        in
          pkgs.writeShellScript "synergyds-start" ''
            cd ${cfg.dataDir}/.steam/root/Steamapps/common/Synergy
            export SRCDS_EXTRA_ARGS=${lib.escapeShellArg cfg.extraCommandLine}
            ${lib.optionalString (cfg.extraCommandLineFile != null) ''export SRCDS_EXTRA_ARGS="$SRCDS_EXTRA_ARGS''${SRCDS_EXTRA_ARGS:+ }$(<"$CREDENTIALS_DIRECTORY/extra-command-line")"''}
            ${pkgs.steam-run}/bin/steam-run env SHELL=/bin/bash ${pkgs.util-linux}/bin/script -qfc ${srcdsScript} /dev/null
          '';

        ExecStop = pkgs.writeShellScript "synergyds-stop" ''
          echo quit > ${fifo}

          # Wait for the PID of the server to disappear before returning,
          # so systemd doesn't attempt to SIGKILL it.
          while kill -0 "$MAINPID" 2> /dev/null; do
            sleep 1s
          done
        '';

        Restart = "always";
        SuccessExitStatus = "0 130";
      };
    };

    my.vm = {
      dataUser = "synergyds";
      console = {
        unit = "synergyds.service";
        input = fifo;
      };
    };
  };
}
