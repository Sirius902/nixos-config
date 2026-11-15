# Minecraft servers for a microVM guest (modules/microvms). Each server runs as
# `mc-<name>` from a foreground `start.sh`, reads its console from a FIFO and
# logs to the journal; `vm console` and the host's snapshots reach it through
# the guest's control port.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.minecraft-servers;

  fifo = name: "/run/mc-${name}.stdin";

  serverOpts = args: let
    server = args.config;
  in {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to define units for this server.";
      };

      dataDir = lib.mkOption {
        type = lib.types.path;
        default = config.my.vm.dataPath;
        defaultText = lib.literalExpression "config.my.vm.dataPath";
        description = "Server working directory (world, mods, configs, start.sh).";
      };

      jdk = lib.mkOption {
        type = lib.types.package;
        default = config.my.jdk;
        defaultText = lib.literalExpression "config.my.jdk";
        description = ''
          JDK/JRE used to launch the server; placed on PATH for `start.sh`.
          Set it for a server whose Minecraft or loader needs another Java:
          1.12 runs only on 8, and a loader's bundled ASM caps how new a
          Java it can read.
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

      serviceConfig = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Escape hatch merged last into serviceConfig.";
      };
    };
  };

  enabledServers = lib.filterAttrs (_: s: s.enable) cfg.servers;

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
    wantedBy = ["multi-user.target"];
    requires = ["mc-${name}.socket"];
    after = ["network.target" "mc-${name}.socket"];
    unitConfig.RequiresMountsFor = [s.dataDir];

    path = [s.jdk];

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
      // s.serviceConfig;
  };

  vmHooks = name: _: {
    dataUser = "mc-${name}";
    # Autosave paused, deliberately with NO `save-all flush`: that serializes
    # every loaded chunk on the server thread, a multi-second tick freeze on a
    # big modded world. The snapshot is atomic, and Minecraft recovers from
    # the crash-consistent state it captures.
    quiesce = ''
      if systemctl is-active --quiet mc-${name}.service; then
        printf 'save-off\n' > ${fifo name}
        sleep 1
      fi
    '';
    resume = ''
      if systemctl is-active --quiet mc-${name}.service; then
        printf 'save-on\n' > ${fifo name}
      fi
    '';
    console = {
      unit = "mc-${name}.service";
      input = fifo name;
    };
  };
in {
  options.services.minecraft-servers = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.servers != {};
      defaultText = lib.literalExpression "config.services.minecraft-servers.servers != {}";
      description = "Whether to run the Minecraft servers.";
    };

    servers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule serverOpts);
      default = {};
      description = "Minecraft server instances, keyed by name (unit = mc-<name>).";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users = lib.mapAttrs' (name: s:
      lib.nameValuePair "mc-${name}" {
        description = "Minecraft server (${name}) service user";
        isSystemUser = true;
        group = "mc-${name}";
        home = s.dataDir;
      })
    enabledServers;

    users.groups = lib.mapAttrs' (name: _: lib.nameValuePair "mc-${name}" {}) enabledServers;

    systemd.services =
      lib.mapAttrs' (name: s: lib.nameValuePair "mc-${name}" (mkService name s)) enabledServers;

    systemd.sockets =
      lib.mapAttrs' (name: s: lib.nameValuePair "mc-${name}" (mkSocket name s)) enabledServers;

    my.vm = lib.mkMerge (lib.mapAttrsToList vmHooks enabledServers);
  };
}
