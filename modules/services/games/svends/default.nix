# Sven Co-op dedicated server for a microVM guest (modules/microvms). It
# updates itself anonymously before every start; `vm console` reaches its
# console, and all output goes to the journal.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.svends;

  fifo = "/run/svends.stdin";
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
      default = config.my.vm.dataPath;
      defaultText = lib.literalExpression "config.my.vm.dataPath";
      description = ''
        Directory the server is installed in, and the service user's home,
        where steamcmd keeps its own install.
      '';
    };

    extraCommandLine = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Extra command-line arguments to pass to svends_run.
      '';
    };

    extraCommandLineFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        File with extra command-line arguments to pass to svends_run,
        read at service start so the contents stay out of the Nix store.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.svends = {
      description = "Sven Co-op server service user";
      home = cfg.dataDir;
      isSystemUser = true;
      group = "svends";
    };

    users.groups.svends = {};

    systemd.services.svends-update = {
      description = "Update Sven Co-op Dedicated Server";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      unitConfig.RequiresMountsFor = [cfg.dataDir];

      # Once per start and without retries: the server starts when this ends
      # either way, and a retry would update the files under it.
      serviceConfig = {
        Type = "oneshot";

        User = "svends";
        Group = "svends";
        WorkingDirectory = cfg.dataDir;

        # No `validate`: it would revert shipped files edited since, such as
        # admins.txt.
        ExecStart = pkgs.writeShellScript "svends-update-start" ''
          ${pkgs.steamcmd}/bin/steamcmd \
            +@ShutdownOnFailedCommand 1 \
            +@NoPromptForPassword 1 \
            +force_install_dir ${cfg.dataDir} \
            +login anonymous \
            +app_update 276060 \
            +quit
        '';
      };
    };

    systemd.sockets.svends = {
      bindsTo = ["svends.service"];
      socketConfig = {
        ListenFIFO = fifo;
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
      wants = ["svends-update.service"];
      after = [
        "network.target"
        "svends.socket"
        "svends-update.service"
      ];
      unitConfig.RequiresMountsFor = [cfg.dataDir] ++ lib.optional (cfg.extraCommandLineFile != null) cfg.extraCommandLineFile;

      serviceConfig = {
        User = "svends";
        Group = "svends";
        WorkingDirectory = cfg.dataDir;

        LoadCredential = lib.mkIf (cfg.extraCommandLineFile != null) [
          "extra-command-line:${cfg.extraCommandLineFile}"
        ];

        StandardInput = "socket";
        StandardOutput = "journal";
        StandardError = "journal";

        TasksMax = 128;
        LimitNOFILE = 4096;

        ExecStart = pkgs.writeShellScript "svends-start" ''
          extra_args=${lib.escapeShellArg cfg.extraCommandLine}
          ${lib.optionalString (cfg.extraCommandLineFile != null) ''extra_args="$extra_args''${extra_args:+ }$(<"$CREDENTIALS_DIRECTORY/extra-command-line")"''}
          ${pkgs.steam-run}/bin/steam-run ./svends_run \
            -console \
            -port ${toString cfg.port} \
            ${lib.optionalString cfg.insecure "-insecure"} \
            +maxplayers ${toString cfg.maxplayers} \
            +map ${lib.escapeShellArg cfg.map} \
            +log on \
            ''${extra_args:+"$extra_args"}
        '';

        ExecStop = pkgs.writeShellScript "svends-stop" ''
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
      dataUser = "svends";
      console = {
        unit = "svends.service";
        input = fifo;
      };
    };
  };
}
