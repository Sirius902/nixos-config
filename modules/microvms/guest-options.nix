{lib, ...}: {
  options.my.vm = {
    dataPath = lib.mkOption {
      type = lib.types.str;
      description = ''
        Where the VM's data share is mounted, the same path as on the host.
        Service modules default their data directory to it.
      '';
    };

    dataUser = lib.mkOption {
      type = lib.types.str;
      description = ''
        Account that runs the server. Every file on the data share appears to
        be its, so the service module that runs the server sets this.
      '';
    };

    quiesce = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Commands, run as root, that bring the server's on-disk state to rest
        before the host snapshots the data share.
      '';
    };

    resume = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Commands that undo `quiesce` once the snapshot is taken.";
    };

    console = lib.mkOption {
      type = lib.types.nullOr (lib.types.submodule {
        options = {
          unit = lib.mkOption {
            type = lib.types.str;
            description = "Server unit whose output the console streams.";
          };
          input = lib.mkOption {
            type = lib.types.str;
            description = "FIFO the server reads its console from.";
          };
        };
      });
      default = null;
      description = "Server console that `vm console` attaches to.";
    };
  };
}
