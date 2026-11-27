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

    dataReferences = lib.mkOption {
      type = lib.types.listOf lib.types.pathInStore;
      default = [];
      description = ''
        Store paths that files on the data share link into. The guest's store
        is not the host's, so the host keeps these in its system closure for
        the links to resolve there too. Only the current system's are kept;
        links an earlier start made dangle until the server repoints them.
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
