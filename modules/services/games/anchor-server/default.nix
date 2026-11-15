# Anchor: the multiplayer sync server for Harbor Masters 64 ports, for a
# microVM guest (modules/microvms). The admin console (`list`, `messageAll`,
# `disableAll`, `deleteRoom`, `stop`) is reached with `vm console`; all output
# goes to the journal.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.anchor-server;

  fifo = "/run/anchor-server.stdin";
in {
  options.services.anchor-server = {
    enable = lib.mkEnableOption "the Anchor server";

    package = lib.mkPackageOption pkgs "anchor-server" {};

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = config.my.vm.dataPath;
      defaultText = lib.literalExpression "config.my.vm.dataPath";
      description = ''
        Server working directory. The server reads `stats.json` and rewrites it
        relative to the CWD, every 30s and on shutdown.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.anchor-server = {
      description = "Anchor server service user";
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
      wantedBy = ["multi-user.target"];
      requires = ["anchor-server.socket"];
      after = ["network.target" "anchor-server.socket"];
      unitConfig.RequiresMountsFor = [cfg.dataDir];

      serviceConfig = {
        User = "anchor-server";
        Group = "anchor-server";
        WorkingDirectory = cfg.dataDir;

        StandardInput = "socket";
        StandardOutput = "journal";
        StandardError = "journal";

        ExecStart = lib.getExe cfg.package;

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
      };
    };

    my.vm = {
      dataUser = "anchor-server";
      console = {
        unit = "anchor-server.service";
        input = fifo;
      };
    };
  };
}
