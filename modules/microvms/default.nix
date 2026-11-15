{
  inputs,
  lib,
  pkgs,
  ...
}: let
  hostSide = name: vm: {
    networking.hostName = name;
    my.vm.dataPath = vm.data.path;
    microvm = {
      inherit (vm) vcpu;
      mem = vm.memory;
      shares =
        [
          {
            proto = "virtiofs";
            tag = "data";
            source = vm.data.path;
            mountPoint = vm.data.path;
            socket = "/run/vm/${name}/fs-data.sock";
          }
        ]
        ++ lib.optional (vm.secrets != {}) {
          proto = "virtiofs";
          tag = "secrets";
          source = "/run/credentials/vm-${name}-fs-secrets.service";
          mountPoint = "/run/credstore";
          socket = "/run/vm/${name}/fs-secrets.sock";
        };
      # The runner only knows tap and macvtap networking.
      cloud-hypervisor.extraArgs = [
        "--net"
        "vhost_user=on,socket=/run/vm/${name}/passt.sock,vhost_mode=client,mac=02:00:00:00:00:01"
      ];
    };
    fileSystems = lib.mkIf (vm.secrets != {}) {
      "/run/credstore".options = ["ro"];
    };
  };

  evalGuest = name: vm:
    (import "${inputs.nixpkgs}/nixos/lib/eval-config.nix" {
      inherit pkgs;
      system = null;
      specialArgs = {inherit inputs;};
      prefix = ["my" "microvms" name "guest"];
      modules = [
        inputs.microvm.nixosModules.microvm
        ./guest.nix
        (hostSide name vm)
        vm.guest
      ];
    })
    .config;

  vmOptions = {
    name,
    config,
    ...
  }: {
    options = {
      vcpu = lib.mkOption {
        type = lib.types.ints.positive;
        description = "Virtual CPUs.";
      };

      memory = lib.mkOption {
        type = lib.types.ints.positive;
        description = ''
          Guest RAM in MiB. VMs may overcommit the host between them;
          `oomScoreAdjust` decides which goes first.
        '';
      };

      ports = {
        tcp = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [];
          description = ''
            TCP ports the VM serves on every host address. VMs that share
            a port with each other are mutually exclusive.
          '';
        };
        udp = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [];
          description = "UDP ports, as for `ports.tcp`.";
        };
      };

      egress = lib.mkOption {
        type = lib.types.enum ["internet" "none"];
        default = "internet";
        description = ''
          Connections the VM may open. `internet` excludes the LAN, the
          tailnet, the host and every other private or special range;
          `none` allows nothing. Neither limits inbound connections.
        '';
      };

      autostart = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether the VM starts with the host.";
      };

      oomScoreAdjust = lib.mkOption {
        type = lib.types.ints.between (-1000) 1000;
        description = "OOM score adjustment of the VM. Higher goes first.";
      };

      data = {
        dataset = lib.mkOption {
          type = lib.types.str;
          example = "data/mc/rl2";
          description = "ZFS dataset holding the VM's data.";
        };
        path = lib.mkOption {
          type = lib.types.str;
          example = "/media/data/mc/servers/rl2";
          description = "Where the dataset is mounted, on the host and in the guest alike.";
        };
        snapshots = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Whether sanoid snapshots the dataset, quiescing the server first
            while the VM runs.
          '';
        };
      };

      secrets = lib.mkOption {
        type = lib.types.attrsOf (lib.types.pathWith {
          inStore = false;
          absolute = true;
        });
        default = {};
        example = lib.literalExpression ''
          {srcdsExtraCommandLine = config.sops.secrets.srcdsExtraCommandLine.path;}
        '';
        description = ''
          Host files, by name, that the guest reads as `/run/credstore/<name>`:
          read-only and root's, so a guest service takes one with
          `LoadCredential=<name>`. Read when the VM starts; they never enter
          the Nix store or a command line.
        '';
      };

      guest = lib.mkOption {
        type = lib.types.deferredModule;
        default = {};
        description = "NixOS module for the guest. It enables the VM's server.";
      };

      system = lib.mkOption {
        type = lib.types.unspecified;
        readOnly = true;
        internal = true;
        description = "The guest's evaluated configuration.";
      };
    };

    config.system = evalGuest name config;
  };
in {
  imports = [./host.nix];

  options.my.microvmOwner = lib.mkOption {
    type = lib.types.str;
    example = "chris";
    description = ''
      Account that owns every VM's data on disk and runs the `vm` command.
      Each VM sees the files through an idmapped view in which they are its
      own, so the owner needs to grant nothing.
    '';
  };

  options.my.microvms = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule vmOptions);
    default = {};
    description = "Servers, each in a microVM of its own. See docs/microvms.md.";
  };
}
