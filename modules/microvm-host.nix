# Host side of this machine's microVMs, plus the guest half of the same wiring
# so the two can never drift. Each VM declares one `index`; its tap name, /30,
# MAC and vsock CID all follow from it.
#
# Point-to-point taps rather than one shared bridge: creating an L2 device is
# the change most likely to strand a host with no physical access, separate
# taps leave untrusted guests unable to reach each other at L2, and
# microvm.nix's `type = "bridge"` goes through qemu-bridge-helper, which the
# cloud-hypervisor runner never invokes.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.microvmHost;

  hexByte = n: lib.fixedWidthString 2 "0" (lib.toLower (lib.toHexString n));

  vmOpts = {name, ...} @ args: let
    vm = args.config;
  in {
    options = {
      index = lib.mkOption {
        type = lib.types.ints.between 0 63;
        example = 1;
        description = ''
          Slot this VM occupies. Every address below is derived from it, so it
          is the only value that has to be kept unique by hand. Bounded by the
          number of /30s that fit in 10.0.0.0/24.
        '';
      };

      forwardedTCPPorts = lib.mkOption {
        type = lib.types.listOf lib.types.port;
        default = [];
        description = ''
          TCP ports DNAT'd from `externalInterface` to the same port on the
          guest. The guest's own firewall is not involved.
        '';
      };

      forwardedUDPPorts = lib.mkOption {
        type = lib.types.listOf lib.types.port;
        default = [];
        description = "UDP ports DNAT'd from `externalInterface` to the guest.";
      };

      oomScoreAdjust = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        example = 1000;
        description = ''
          OOMScoreAdjust for the hypervisor process. Raise it to make a VM the
          thing the kernel sacrifices before any host service if the host runs
          out of memory; order the VMs against each other by how much each one
          costs to lose.
        '';
      };

      tap = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Host tap interface for this VM.";
      };

      hostAddress = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Host end of the point-to-point /30.";
      };

      guestAddress = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Guest end of the point-to-point /30, and its default gateway's peer.";
      };

      mac = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Guest NIC address, in the locally-administered range.";
      };

      cid = lib.mkOption {
        type = lib.types.ints.positive;
        readOnly = true;
        description = "vsock context id, which `microvm -s <name>` connects to.";
      };
    };

    config = {
      tap = "vm-${lib.removeSuffix "-vm" name}";
      hostAddress = "10.0.0.${toString (4 * vm.index + 1)}";
      guestAddress = "10.0.0.${toString (4 * vm.index + 2)}";
      mac = "02:00:00:00:0a:${hexByte (vm.index + 1)}";
      cid = 42 + vm.index;
    };
  };

  protoPorts = vm:
    map (port: {
      proto = "tcp";
      inherit port;
    })
    vm.forwardedTCPPorts
    ++ map (port: {
      proto = "udp";
      inherit port;
    })
    vm.forwardedUDPPorts;

  # Every forwarded port as a pair of iptables rule specs, split so the same
  # spec drives the -C probe, the -I insert and the -D teardown.
  rules = vm:
    lib.concatMap ({
      proto,
      port,
    }: [
      {
        table = "-t nat ";
        chain = "PREROUTING";
        args = "-i ${cfg.externalInterface} -p ${proto} --dport ${toString port} -j DNAT --to-destination ${vm.guestAddress}:${toString port}";
      }
      {
        table = "";
        chain = "FORWARD";
        args = "-i ${cfg.externalInterface} -o ${vm.tap} -d ${vm.guestAddress} -p ${proto} --dport ${toString port} -j ACCEPT";
      }
    ]) (protoPorts vm);

  addRule = r: "iptables ${r.table}-C ${r.chain} ${r.args} 2>/dev/null \\\n  || iptables ${r.table}-I ${r.chain} ${r.args}";
  delRule = r: "iptables ${r.table}-D ${r.chain} ${r.args} 2>/dev/null || true\n";

  # NetworkManager is told to ignore the tap at runtime (nmcli, not its config)
  # so it is never reloaded — only ever touching this VM's tap, never the
  # host's uplink or Tailscale.
  hostnetService = name: vm: {
    description = "Host-side networking for ${name} (tap IP + game-port forward)";
    after = ["microvm-tap-interfaces@${name}.service"];
    bindsTo = ["microvm-tap-interfaces@${name}.service"];
    partOf = ["microvm@${name}.service"];
    wantedBy = ["microvm@${name}.service"];
    path = [pkgs.iproute2 pkgs.networkmanager pkgs.iptables];
    serviceConfig =
      {
        Type = "oneshot";
        RemainAfterExit = true;
      }
      // lib.optionalAttrs (rules vm != []) {
        # Remove the forwards when the VM stops, so its ports aren't shadowed
        # on the host while it is off.
        ExecStop = pkgs.writeShellScript "${name}-forward-down" (lib.concatMapStrings delRule (rules vm));
      };
    script =
      ''
        nmcli device set ${vm.tap} managed no 2>/dev/null || true
        ip addr replace ${vm.hostAddress}/30 dev ${vm.tap}
        ip link set ${vm.tap} up
      ''
      + lib.optionalString (rules vm != []) ''

        # -C guards make this idempotent on restart; -I beats any default-drop in FORWARD.
        ${lib.concatMapStringsSep "\n" addRule (rules vm)}
      '';
  };

  # The guest half, carried into the VM's own evaluation so a tap, MAC or /30
  # can only ever be spelled once.
  guestModule = vm: {
    microvm = {
      interfaces = [
        {
          type = "tap";
          id = vm.tap;
          inherit (vm) mac;
        }
      ];
      # vsock is the `microvm -s` login. NB: setting the cid also arms
      # microvm.nix's notify relay (the boot killer) — neutralised in the host
      # dropin below (#474).
      vsock.cid = vm.cid;
      vsock.ssh.enable = true;
    };

    # Route + DNS via the host's NAT for whatever the guest has to reach
    # outbound; wait-online off so the link can't stall boot.
    systemd.network.enable = true;
    systemd.network.wait-online.enable = false;
    systemd.network.networks."10-host" = {
      matchConfig.MACAddress = vm.mac;
      address = ["${vm.guestAddress}/30"];
      routes = [{Gateway = vm.hostAddress;}];
      networkConfig.IPv6AcceptRA = false;
    };
    networking.nameservers = ["1.1.1.1"]; # static resolv.conf — resolved off below
    services.resolved.enable = false;
  };

  indexes = lib.mapAttrsToList (_: vm: vm.index) cfg.vms;
  forwards = lib.concatMap (vm: map (p: "${p.proto}/${toString p.port}") (protoPorts vm)) (lib.attrValues cfg.vms);
  repeated = xs: lib.unique (lib.filter (x: lib.count (y: y == x) xs > 1) xs);
in {
  imports = [inputs.microvm.nixosModules.host];

  options.my.microvmHost = {
    enable = lib.mkEnableOption "the microVM host";

    externalInterface = lib.mkOption {
      type = lib.types.str;
      example = "eno2";
      description = "Uplink the guests are NAT'd out of and forwarded in from.";
    };

    identityFile = lib.mkOption {
      type = lib.types.path;
      example = "/home/user/.ssh/id_ed25519";
      description = ''
        SSH key root presents to `vsock-mux/*` and `vsock/*` hosts, which is how
        `microvm -s` and any unit driving a guest authenticate. Remove it and
        those logins break.
      '';
    };

    vms = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule vmOpts);
      default = {};
      description = ''
        Networking for each declarative microVM, keyed by the `microvm.vms`
        name it belongs to. A name with no such entry is an evaluation error.
      '';
    };
  };

  config = lib.mkMerge [
    {microvm.host.enable = cfg.enable;}

    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = repeated indexes == [];
          message = "my.microvmHost.vms: `index` decides every address, so it must be unique. Reused: ${lib.concatMapStringsSep ", " toString (repeated indexes)}.";
        }
        {
          assertion = repeated forwards == [];
          message = "my.microvmHost.vms: two VMs claim the same forwarded port: ${lib.concatStringsSep ", " (repeated forwards)}.";
        }
      ];

      programs.ssh.extraConfig = ''
        Host vsock-mux/* vsock/*
          IdentityFile ${cfg.identityFile}
          IdentitiesOnly yes
      '';

      networking.nat = {
        enable = true;
        internalInterfaces = lib.mapAttrsToList (_: vm: vm.tap) cfg.vms;
        inherit (cfg) externalInterface;
      };

      systemd.services =
        lib.mapAttrs' (name: vm: lib.nameValuePair "${name}-hostnet" (hostnetService name vm)) cfg.vms
        # Boot fix (#474): vsock.cid arms microvm.nix's socat notify relay whose
        # 2s timeout stalls boot; Type=simple + NotifyAccess=none leaves
        # NOTIFY_SOCKET unset so it never starts.
        // lib.mapAttrs' (name: vm:
          lib.nameValuePair "microvm@${name}" {
            overrideStrategy = "asDropin";
            serviceConfig =
              {
                Type = lib.mkForce "simple";
                NotifyAccess = lib.mkForce "none";
              }
              // lib.optionalAttrs (vm.oomScoreAdjust != null) {
                OOMScoreAdjust = vm.oomScoreAdjust;
              };
          })
        cfg.vms;

      microvm.vms = lib.mapAttrs (_: vm: {extraModules = [(guestModule vm)];}) cfg.vms;
    })
  ];
}
