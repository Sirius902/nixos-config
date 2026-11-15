{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.microvms;
  owner = config.my.microvmOwner;
  names = lib.attrNames cfg;

  runnerOf = name: cfg.${name}.system.microvm.declaredRunner;

  portsOf = vm:
    map (p: "tcp/${toString p}") vm.ports.tcp
    ++ map (p: "udp/${toString p}") vm.ports.udp;
  shared = a: b: lib.intersectLists (portsOf cfg.${a}) (portsOf cfg.${b});
  partners = name: lib.filter (other: other != name && shared name other != []) names;

  hasSecrets = name: cfg.${name}.secrets != {};

  # Every unit of a VM, in start order.
  unitsOf = name:
    [
      "vm-${name}-preflight.service"
      "vm-${name}-share.service"
      "vm-${name}-fs-data.socket"
      "vm-${name}-fs-data.service"
    ]
    ++ lib.optionals (hasSecrets name) [
      "vm-${name}-fs-secrets.socket"
      "vm-${name}-fs-secrets.service"
    ]
    ++ [
      "vm-${name}-net.service"
      "vm-${name}.service"
    ];

  # systemd runs a stop job before a start job whenever the two units are
  # ordered either way round. Ordering each unit of a VM after every unit of
  # the partners whose names sort first therefore stops a whole partner, the
  # passt holding the port included, before this VM's preflight runs, in
  # whichever direction the switch goes; one direction per pair rules out
  # ordering cycles.
  partnerOrder = name: lib.concatMap unitsOf (lib.filter (p: p < name) (partners name));

  sandbox = {
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    CapabilityBoundingSet = [""];
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    ProtectClock = true;
    ProtectHostname = true;
    LockPersonality = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
    MemoryDenyWriteExecute = true;
  };

  vmUser = name: {
    User = "vm-${name}";
    Group = "vm-${name}";
  };

  # Mount points only, so virtiofsd sees nothing of the host beyond its binds.
  emptyRoot = pkgs.runCommand "vm-empty-root" {} ''
    mkdir -p $out/{dev,nix/store,proc,run,share,sys,tmp,var/tmp}
  '';

  virtiofsdSandbox =
    sandbox
    // {
      RootDirectory = emptyRoot;
      MountAPIVFS = true;
      BindReadOnlyPaths = ["/nix/store"];
      PrivateDevices = true;
      PrivateNetwork = true;
      RestrictNamespaces = true;
      RestrictAddressFamilies = ["AF_UNIX"];
      ProtectProc = "invisible";
      # virtiofsd raises its own file limit to a million at startup,
      # reading /proc/sys/fs/nr_open even when told not to (so no
      # ProcSubset=pid); unprivileged, it can't, so it gets it here.
      LimitNOFILE = 1048576;
      UMask = "0077";
    };

  preflight = pkgs.writeShellApplication {
    name = "vm-preflight";
    runtimeInputs = [config.boot.zfs.package pkgs.coreutils pkgs.findutils pkgs.gnused pkgs.util-linux];
    text = builtins.readFile ./preflight.sh;
  };

  shareUp = name: vm:
    pkgs.writeShellApplication {
      name = "vm-${name}-share";
      runtimeInputs = [pkgs.coreutils pkgs.util-linux];
      text = ''
        view=/run/vm-fs/${name}/share
        mkdir -p "$view"
        if mountpoint -q "$view"; then
          umount --lazy "$view"
        fi
        # On-disk owner first: the owner's files show as the VM user's, and
        # the VM user's writes are stored as the owner's.
        map="u:$(id -u ${owner}):$(id -u vm-${name}):1 g:$(id -g ${owner}):$(id -g vm-${name}):1"
        mount --bind -o X-mount.idmap="$map" ${lib.escapeShellArg vm.data.path} "$view"
        mount -o remount,bind,nosuid,nodev,noexec "$view"
      '';
    };

  virtiofsd = name: vm: let
    guest = vm.system;
    dataUser = guest.users.users.${guest.my.vm.dataUser};
  in
    pkgs.writeShellScript "vm-${name}-virtiofsd" ''
      exec ${lib.getExe pkgs.virtiofsd} --fd=3 --shared-dir=/share --sandbox=none \
        --inode-file-handles=never --cache=auto \
        --thread-pool-size=${toString vm.vcpu} \
        --translate-uid=squash-guest:0:"$(${pkgs.coreutils}/bin/id -u)":4294967295 \
        --translate-uid=squash-host:0:${toString dataUser.uid}:4294967295 \
        --translate-gid=squash-guest:0:"$(${pkgs.coreutils}/bin/id -g)":4294967295 \
        --translate-gid=squash-host:0:${toString guest.users.groups.${dataUser.group}.gid}:4294967295
    '';

  # Serves the VM's secrets, which systemd has loaded as this unit's
  # credentials, as root's files.
  secretsd = name:
    pkgs.writeShellScript "vm-${name}-secretsd" ''
      exec ${lib.getExe pkgs.virtiofsd} --fd=3 --shared-dir="$CREDENTIALS_DIRECTORY" --readonly \
        --sandbox=none --inode-file-handles=never --cache=auto \
        --translate-uid=squash-host:0:0:4294967295 \
        --translate-gid=squash-host:0:0:4294967295
    '';

  portArg = flag: ports:
    lib.optionals (ports != []) [flag (lib.concatMapStringsSep "," toString ports)];

  passt = name: vm:
    lib.escapeShellArgs (
      [
        (lib.getExe pkgs.passt)
        "--vhost-user"
        "--socket-path"
        "/run/vm/${name}/passt.sock"
        "--ipv4-only"
        "--map-host-loopback"
        "none"
        "--address"
        "10.0.2.15"
        "--netmask"
        "24"
        "--gateway"
        "10.0.2.2"
        "--repair-path"
        "none"
        "--pid"
        "/run/vm/${name}/passt.pid"
        "--dns"
        "none"
        "--search"
        "none"
        "--quiet"
      ]
      ++ portArg "--tcp-ports" vm.ports.tcp
      ++ portArg "--udp-ports" vm.ports.udp
    );

  # vm-control <name> <command>: one command to the guest's control port,
  # which answers ok.
  vmControl = pkgs.writeShellScript "vm-control" ''
    printf 'CONNECT 1024\n%s\n' "$2" \
      | ${lib.getExe pkgs.socat} -t 10 - "UNIX-CONNECT:/run/vm/$1/vsock.sock" \
      | ${pkgs.gnugrep}/bin/grep -qx ok
  '';

  preSnapshot = name: vm:
    pkgs.writeShellScript "vm-${name}-pre-snapshot" ''
      if ! ${config.systemd.package}/bin/systemctl is-active --quiet vm-${name}.service; then
        # Off: snapshot only if something changed since the last one.
        written=$(${config.boot.zfs.package}/bin/zfs get -Hp -o value written ${lib.escapeShellArg vm.data.dataset}) || exit 1
        if [ "$written" = 0 ]; then
          echo "vm-${name}: off and unchanged since its last snapshot; skipping" >&2
          exit 1
        fi
        exit 0
      fi
      # A snapshot of a running server is crash-consistent even unquiesced.
      ${vmControl} ${name} quiesce || echo "vm-${name}: quiesce failed; snapshotting anyway" >&2
    '';

  postSnapshot = name:
    pkgs.writeShellScript "vm-${name}-post-snapshot" ''
      if ${config.systemd.package}/bin/systemctl is-active --quiet vm-${name}.service; then
        ${vmControl} ${name} resume || echo "vm-${name}: resume failed" >&2
      fi
      exit 0
    '';

  vmUnits = name: vm: {
    services."vm-${name}-preflight" = {
      description = "VM ${name}: preflight";
      after = ["zfs-mount.service"] ++ partnerOrder name;
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.escapeShellArgs [(lib.getExe preflight) name vm.data.dataset vm.data.path owner];
        # Read-only: root only for /dev/zfs and to look into the owner's
        # private directories.
        CapabilityBoundingSet = ["CAP_DAC_READ_SEARCH"];
        DevicePolicy = "closed";
        DeviceAllow = ["/dev/zfs rw"];
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        PrivateTmp = true;
        PrivateNetwork = true;
        RestrictAddressFamilies = ["AF_UNIX"];
      };
    };

    services."vm-${name}-share" = {
      description = "VM ${name}: idmapped view of its data";
      requires = ["vm-${name}-preflight.service"];
      after = ["vm-${name}-preflight.service"] ++ partnerOrder name;
      # Like every helper of the VM, gone with it however it ends; PartOf
      # would leave them up, passt holding the ports, when it fails.
      bindsTo = ["vm-${name}.service"];
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = lib.getExe (shareUp name vm);
        ExecStop = "${pkgs.util-linux}/bin/umount --lazy /run/vm-fs/${name}/share";
      };
    };

    sockets."vm-${name}-fs-data" = {
      description = "VM ${name}: virtiofs socket";
      requires = ["vm-${name}-preflight.service"];
      after = ["vm-${name}-preflight.service"] ++ partnerOrder name;
      bindsTo = ["vm-${name}.service"];
      socketConfig = {
        ListenStream = "/run/vm/${name}/fs-data.sock";
        SocketUser = "vm-${name}";
        SocketMode = "0600";
        RemoveOnStop = true;
      };
    };

    services."vm-${name}-fs-data" = {
      description = "VM ${name}: virtiofs server";
      # Socket-activated, so it must pull nothing in: through the VM, whatever
      # it started would rerun the preflight when cloud-hypervisor connects.
      requisite = ["vm-${name}-share.service"];
      after = ["vm-${name}-share.service"] ++ partnerOrder name;
      partOf = ["vm-${name}.service"];
      restartIfChanged = false;
      serviceConfig =
        virtiofsdSandbox
        // vmUser name
        // {
          ExecStart = virtiofsd name vm;
          BindPaths = ["/run/vm-fs/${name}/share:/share"];
        };
    };

    sockets."vm-${name}-fs-secrets" = lib.mkIf (hasSecrets name) {
      description = "VM ${name}: virtiofs socket for its secrets";
      requires = ["vm-${name}-preflight.service"];
      after = ["vm-${name}-preflight.service"] ++ partnerOrder name;
      bindsTo = ["vm-${name}.service"];
      socketConfig = {
        ListenStream = "/run/vm/${name}/fs-secrets.sock";
        SocketUser = "vm-${name}";
        SocketMode = "0600";
        RemoveOnStop = true;
      };
    };

    services."vm-${name}-fs-secrets" = lib.mkIf (hasSecrets name) {
      description = "VM ${name}: virtiofs server for its secrets";
      after = partnerOrder name;
      partOf = ["vm-${name}.service"];
      restartIfChanged = false;
      serviceConfig =
        virtiofsdSandbox
        // vmUser name
        // {
          ExecStart = secretsd name;
          LoadCredential = lib.mapAttrsToList (secret: path: "${secret}:${path}") vm.secrets;
        };
    };

    services."vm-${name}-net" = {
      description = "VM ${name}: passt";
      requires = ["vm-${name}-preflight.service" "vm-egress.service"];
      wants = ["network-online.target"];
      after = ["vm-${name}-preflight.service" "vm-egress.service" "network-online.target"] ++ partnerOrder name;
      bindsTo = ["vm-${name}.service"];
      restartIfChanged = false;
      serviceConfig =
        sandbox
        // vmUser name
        // {
          Type = "forking";
          PIDFile = "/run/vm/${name}/passt.pid";
          ExecStart = passt name vm;
          ReadWritePaths = ["/run/vm/${name}"];
          UMask = "0077";
          # passt sandboxes itself in these.
          RestrictNamespaces = "user mnt uts ipc pid";
          RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK"];
        };
    };

    services."vm-${name}" = {
      description = "VM ${name}";
      requires =
        [
          "vm-${name}-preflight.service"
          "vm-${name}-share.service"
          "vm-${name}-fs-data.socket"
          "vm-${name}-net.service"
        ]
        ++ lib.optional (hasSecrets name) "vm-${name}-fs-secrets.socket";
      wants = ["vm-${name}-vsock.socket"];
      after = lib.remove "vm-${name}.service" (unitsOf name) ++ partnerOrder name;
      conflicts = map (p: "vm-${p}.service") (partners name);
      wantedBy = lib.optional vm.autostart "multi-user.target";
      restartIfChanged = false;
      serviceConfig =
        sandbox
        // vmUser name
        // {
          Type = "notify";
          NotifyAccess = "all";
          WorkingDirectory = "/run/vm/${name}";
          ReadWritePaths = ["/run/vm/${name}"];
          UMask = "0027";
          # What is running, for `vm status` to compare with what is current.
          ExecStartPre = pkgs.writeShellScript "vm-${name}-record-runner" ''
            echo ${runnerOf name} > /run/vm/${name}/runner
          '';
          ExecStart = "${runnerOf name}/bin/microvm-run";
          ExecStop = "${runnerOf name}/bin/microvm-shutdown";
          TimeoutStartSec = "10min";
          TimeoutStopSec = "5min";
          OOMScoreAdjust = vm.oomScoreAdjust;
          DevicePolicy = "closed";
          DeviceAllow = ["/dev/kvm rw"];
          PrivateNetwork = true;
          RestrictNamespaces = true;
          RestrictAddressFamilies = ["AF_UNIX"];
          ProtectProc = "invisible";
          ProcSubset = "pid";
        };
    };

    # cloud-hypervisor creates its sockets owner-only whatever the umask, so
    # vm-admin reaches the guest's vsock through this relay.
    sockets."vm-${name}-vsock" = {
      description = "VM ${name}: vsock for vm-admin";
      bindsTo = ["vm-${name}.service"];
      after = ["vm-${name}.service"];
      socketConfig = {
        ListenStream = "/run/vm/${name}/vsock.sock";
        SocketGroup = "vm-admin";
        SocketMode = "0660";
        Accept = true;
        RemoveOnStop = true;
      };
    };

    services."vm-${name}-vsock@" = {
      description = "VM ${name}: vsock connection";
      serviceConfig =
        sandbox
        // vmUser name
        // {
          # By default socat hangs up half a second after the client has sent
          # its command, before a slower answer such as a quiesce's arrives.
          ExecStart = "${lib.getExe pkgs.socat} -t 60 STDIO UNIX-CONNECT:/run/vm/${name}/notify.vsock";
          StandardInput = "socket";
          PrivateDevices = true;
          PrivateNetwork = true;
          RestrictNamespaces = true;
          RestrictAddressFamilies = ["AF_UNIX"];
          ProtectProc = "invisible";
          ProcSubset = "pid";
        };
    };
  };

  # Matches VM users only, so it can never touch the host's own traffic, and
  # only new connections, so players and the replies to them pass.
  egressRules = let
    users = vms: "{ ${lib.concatMapStringsSep ", " (n: ''"vm-${n}"'') vms} }";
    withEgress = mode: lib.filter (n: cfg.${n}.egress == mode) names;
    rules =
      lib.optional (withEgress "internet" != [])
      "meta skuid ${users (withEgress "internet")} ct state new ip daddr @blocked4 reject"
      ++ lib.optional (withEgress "none" != [])
      "meta skuid ${users (withEgress "none")} ct state new reject"
      ++ ["meta skuid ${users names} meta nfproto ipv6 reject"];
  in
    pkgs.writeText "vm-egress.nft" ''
      table inet microvm
      delete table inet microvm
      table inet microvm {
        set blocked4 {
          type ipv4_addr
          flags interval
          elements = { 0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/4, 240.0.0.0/4 }
        }
        chain output {
          type filter hook output priority filter; policy accept;
          ${lib.concatStringsSep "\n    " rules}
        }
      }
    '';

  inventory = pkgs.writeText "vm-inventory" (lib.concatMapStrings (name: let
    vm = cfg.${name};
  in
    lib.concatStringsSep "|" [
      name
      (toString (portsOf vm))
      (toString vm.memory)
      (toString vm.vcpu)
      (toString (map (p: "${p}=${lib.concatStringsSep "," (shared name p)}") (partners name)))
      "${runnerOf name}"
      (
        if vm.autostart
        then "yes"
        else "no"
      )
      vm.data.dataset
      vm.data.path
    ]
    + "\n")
  names);

  cli = pkgs.writeShellApplication {
    name = "vm";
    runtimeInputs = [config.systemd.package pkgs.coreutils pkgs.gnused pkgs.openssh pkgs.socat];
    text = builtins.replaceStrings ["@inventory@"] ["${inventory}"] (builtins.readFile ./vm.sh);
  };

  snapshotted = lib.filterAttrs (_: vm: vm.data.snapshots) cfg;
in {
  config = lib.mkIf (cfg != {}) {
    assertions =
      map (name: {
        assertion = builtins.match "[a-z][a-z0-9-]{0,28}" name != null;
        message = "my.microvms.${name}: names are lowercase letters, digits and dashes, at most 29 long, since each becomes the user vm-${name}.";
      })
      names
      ++ lib.concatMap (name:
        map (p: {
          assertion = !(cfg.${name}.autostart && cfg.${p}.autostart);
          message = "my.microvms: ${name} and ${p} both autostart but share ${toString (shared name p)}; only one of them can hold it at boot.";
        }) (lib.filter (p: p > name) (partners name)))
      names
      ++ [
        {
          assertion = lib.allUnique (map (n: cfg.${n}.data.dataset) names);
          message = "my.microvms: each VM needs a dataset of its own.";
        }
        {
          assertion = lib.allUnique (map (n: cfg.${n}.data.path) names);
          message = "my.microvms: each VM needs a data path of its own.";
        }
      ];

    users.users = lib.mapAttrs' (name: _:
      lib.nameValuePair "vm-${name}" {
        description = "VM ${name}";
        isSystemUser = true;
        group = "vm-${name}";
      })
    cfg;
    users.groups =
      lib.mapAttrs' (name: _: lib.nameValuePair "vm-${name}" {}) cfg
      // {vm-admin.members = [owner];};

    systemd = lib.mkMerge (lib.mapAttrsToList vmUnits cfg
      ++ [
        {
          tmpfiles.rules =
            [
              "d /run/vm 0755 root root - -"
              "d /run/vm-fs 0700 root root - -"
              # cloud-hypervisor asks for huge pages on guest RAM; shared
              # memory only honours that with advise.
              "w /sys/kernel/mm/transparent_hugepage/shmem_enabled - - - - advise"
            ]
            ++ lib.concatMap (name: [
              "d /run/vm/${name} 2750 vm-${name} vm-admin - -"
              "d /run/vm-fs/${name} 0700 root root - -"
            ])
            names;

          # Reloaded, not restarted, on a switch: a restart would take every
          # running VM down with it.
          services.vm-egress = {
            description = "Egress rules for VMs";
            wantedBy = ["multi-user.target"];
            reloadIfChanged = true;
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${lib.getExe pkgs.nftables} -f ${egressRules}";
              ExecReload = "${lib.getExe pkgs.nftables} -f ${egressRules}";
              ExecStop = "${lib.getExe pkgs.nftables} delete table inet microvm";
            };
          };

          services.sanoid.serviceConfig.SupplementaryGroups = lib.mkIf (snapshotted != {}) ["vm-admin"];
        }
      ]);

    networking.firewall.allowedTCPPorts = lib.unique (lib.concatMap (vm: vm.ports.tcp) (lib.attrValues cfg));
    networking.firewall.allowedUDPPorts = lib.unique (lib.concatMap (vm: vm.ports.udp) (lib.attrValues cfg));

    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function (action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == ${builtins.toJSON owner} &&
            ${builtins.toJSON (lib.concatMap (n: ["vm-${n}.service" "vm-${n}-preflight.service"]) names)}.indexOf(action.lookup("unit")) >= 0 &&
            ["start", "stop", "restart", "kill"].indexOf(action.lookup("verb")) >= 0) {
          return polkit.Result.YES;
        }
      });
    '';

    services.sanoid = lib.mkIf (snapshotted != {}) {
      enable = true;
      templates.vm = {
        frequently = 0;
        hourly = 48;
        daily = 14;
        weekly = 4;
        monthly = 3;
        yearly = 0;
        autosnap = true;
        autoprune = true;
        no_inconsistent_snapshot = true;
        force_post_snapshot_script = true;
        script_timeout = 60;
      };
      datasets = lib.mapAttrs' (name: vm:
        lib.nameValuePair vm.data.dataset {
          useTemplate = ["vm"];
          pre_snapshot_script = "${preSnapshot name vm}";
          post_snapshot_script = "${postSnapshot name}";
        })
      snapshotted;
    };

    environment.systemPackages = [cli];
  };
}
