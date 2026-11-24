# TES3MP dedicated server for a microVM guest (modules/microvms). Every start
# links the packaged CoreScripts into the server's home, beside the world it
# saves there. It has no console; all output goes to the journal.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.tes3mp-server;

  settingsFormat = pkgs.formats.ini {};
in {
  options.services.tes3mp-server = {
    enable = lib.mkEnableOption "the TES3MP server";

    package = lib.mkPackageOption pkgs "tes3mp-server" {};

    corescripts = lib.mkPackageOption pkgs "tes3mp-corescripts" {};

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = config.my.vm.dataPath;
      defaultText = lib.literalExpression "config.my.vm.dataPath";
      description = ''
        Directory holding the server's home, `server/` unless
        `settings.Plugins.home` says otherwise.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 25565;
      description = "UDP port the server listens on.";
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = settingsFormat.type;
      };
      default = {};
      description = ''
        `tes3mp-server.cfg`, read over the package's
        `tes3mp-server-default.cfg`. Each default here can be overridden on
        its own; the master server is off, so the server stays unlisted.
      '';
    };

    passwordFile = lib.mkOption {
      type = lib.types.nullOr (lib.types.pathWith {
        inStore = false;
        absolute = true;
      });
      default = null;
      description = ''
        File holding the password players join with, read at service start so
        it stays out of the Nix store.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.passwordFile == null || !(cfg.settings.General ? password);
        message = "services.tes3mp-server: set passwordFile or settings.General.password, not both; the server rejects a setting given twice.";
      }
      {
        assertion = lib.hasPrefix "/" (toString cfg.settings.Plugins.home);
        message = "services.tes3mp-server: settings.Plugins.home must be absolute; the server resolves a relative one inside its package.";
      }
    ];

    services.tes3mp-server.settings = {
      General = {
        localAddress = lib.mkDefault "0.0.0.0";
        port = lib.mkDefault cfg.port;
        hostname = lib.mkDefault "TES3MP server";
        maximumPlayers = lib.mkDefault 64;
        logLevel = lib.mkDefault 1;
      };
      Plugins = {
        home = lib.mkDefault "${cfg.dataDir}/server";
        plugins = lib.mkDefault "serverCore.lua";
      };
      MasterServer.enabled = lib.mkDefault false;
    };

    users.users.tes3mp-server = {
      description = "TES3MP server service user";
      isSystemUser = true;
      group = "tes3mp-server";
    };

    users.groups.tes3mp-server = {};

    systemd.services.tes3mp-server = {
      description = "TES3MP server";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      unitConfig.RequiresMountsFor = [cfg.dataDir] ++ lib.optional (cfg.passwordFile != null) cfg.passwordFile;

      environment = {
        XDG_CONFIG_HOME = "/run/tes3mp-server";
        XDG_DATA_HOME = "/run/tes3mp-server";
      };

      serviceConfig = {
        User = "tes3mp-server";
        Group = "tes3mp-server";
        RuntimeDirectory = "tes3mp-server";
        RuntimeDirectoryMode = "0700";

        LoadCredential = lib.mkIf (cfg.passwordFile != null) [
          "password:${cfg.passwordFile}"
        ];

        ExecStart = pkgs.writeShellScript "tes3mp-server-start" ''
          set -euo pipefail

          src=${cfg.corescripts}/share/tes3mp-corescripts
          home=${lib.escapeShellArg cfg.settings.Plugins.home}

          # The server rewrites data/, so its files start as copies; everything
          # else links to the package unless an admin replaced it with a real file.
          mkdir -p "$home"
          while IFS= read -r -d "" dir; do
            mkdir -p "$home/$dir"
          done < <(find "$src" -mindepth 1 -type d -printf '%P\0')
          while IFS= read -r -d "" file; do
            case $file in
              data/*)
                [ -e "$home/$file" ] || install -D -m 0644 "$src/$file" "$home/$file"
                ;;
              *)
                if [ ! -e "$home/$file" ] || [ -L "$home/$file" ]; then
                  ln -sfn "$src/$file" "$home/$file"
                fi
                ;;
            esac
          done < <(find "$src" -type f -printf '%P\0')
          find "$home" -xtype l -lname '/nix/store/*' -delete

          mkdir -p "$XDG_CONFIG_HOME/tes3mp"
          cat ${settingsFormat.generate "tes3mp-server.cfg" cfg.settings} > "$XDG_CONFIG_HOME/tes3mp/tes3mp-server.cfg"
          ${lib.optionalString (cfg.passwordFile != null) ''
            printf '\n[General]\npassword = %s\n' "$(< "$CREDENTIALS_DIRECTORY/password")" >> "$XDG_CONFIG_HOME/tes3mp/tes3mp-server.cfg"
          ''}
          exec ${lib.getExe cfg.package} --no-logs
        '';

        Restart = "always";
        RestartSec = "10s";
      };
    };

    my.vm.dataUser = "tes3mp-server";
  };
}
