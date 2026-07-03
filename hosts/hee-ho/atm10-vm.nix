# Prod atm10 in a microVM: the untrusted, never-patched modded server isolated by
# the hypervisor rather than by in-guest systemd hardening. Careful never to disturb
# hee-ho's own networking (remote, no physical access).
{
  inputs,
  lib,
  pkgs,
  ...
}: let
  mcId = 992; # existing world-file owner; host and guest must share it over virtiofs
  mcGid = 990;
  dataDir = "/media/data/mc/servers/atm10";
  zfsDataset = "data/mc/atm10";
  mcServers = ../../modules/services/games/minecraft-servers;
  fifo = "/run/mc-atm10.stdin";
  saveSock = "/run/mc-atm10-save.sock";
  microvmCmd = pkgs.callPackage "${inputs.microvm}/pkgs/microvm-command.nix" {};

  # Socket handler (root): reads exactly `off`/`on` from the connection — input is never
  # interpolated into a command — and toggles the guest's autosave over vsock, settling
  # before it returns so the pause lands before the snapshot. is-active no-ops a stopped
  # server; `|| true` a powered-off VM — the snapshot proceeds either way.
  saveHandler = pkgs.writeShellScript "mc-atm10-save-handler" ''
    read -r cmd || cmd=""
    case "$cmd" in
      off) ${lib.getExe microvmCmd} -s atm10-vm "systemctl is-active -q mc-atm10 && echo save-off > ${fifo}" || true; sleep 1 ;;
      on)  ${lib.getExe microvmCmd} -s atm10-vm "systemctl is-active -q mc-atm10 && echo save-on > ${fifo}" || true ;;
      *)   exit 1 ;;
    esac
  '';
in {
  imports = [inputs.microvm.nixosModules.host];

  # The native mc-atm10 service used to define this user; it's gone now, but the world
  # files keep its ownership and the VM writes them (over virtiofs) as this id, so pin
  # it host-side too. chris is in the group for host-side file access.
  users.users.mc-atm10 = {
    uid = mcId;
    isSystemUser = true;
    group = "mc-atm10";
  };
  users.groups.mc-atm10 = {
    gid = mcGid;
    members = ["chris"];
  };

  # How `microvm -s` (and the backup units) authenticate: root borrows chris's key for
  # vsock hosts. Remove it and the login breaks.
  programs.ssh.extraConfig = ''
    Host vsock-mux/* vsock/*
      IdentityFile /home/chris/.ssh/id_ed25519
      IdentitiesOnly yes
  '';

  # NetworkManager is told to ignore the tap at runtime (nmcli, not its config) so it
  # is never reloaded — only ever touching vm-atm10, never eno2/Tailscale.
  systemd.services."atm10-vm-hostnet" = {
    description = "Host-side networking for atm10-vm (tap IP + game-port forward)";
    after = ["microvm-tap-interfaces@atm10-vm.service"];
    bindsTo = ["microvm-tap-interfaces@atm10-vm.service"];
    partOf = ["microvm@atm10-vm.service"];
    wantedBy = ["microvm@atm10-vm.service"];
    path = [pkgs.iproute2 pkgs.networkmanager pkgs.iptables];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Remove the forward when the VM stops, so host:25565 isn't shadowed while off.
      ExecStop = pkgs.writeShellScript "atm10-vm-forward-down" ''
        iptables -t nat -D PREROUTING -i eno2 -p tcp --dport 25565 -j DNAT --to-destination 10.0.0.2:25565 2>/dev/null || true
        iptables -D FORWARD -i eno2 -o vm-atm10 -d 10.0.0.2 -p tcp --dport 25565 -j ACCEPT 2>/dev/null || true
      '';
    };
    script = ''
      nmcli device set vm-atm10 managed no 2>/dev/null || true
      ip addr replace 10.0.0.1/30 dev vm-atm10
      ip link set vm-atm10 up

      # -C guards make this idempotent on restart; -I beats any default-drop in FORWARD.
      iptables -t nat -C PREROUTING -i eno2 -p tcp --dport 25565 -j DNAT --to-destination 10.0.0.2:25565 2>/dev/null \
        || iptables -t nat -I PREROUTING -i eno2 -p tcp --dport 25565 -j DNAT --to-destination 10.0.0.2:25565
      iptables -C FORWARD -i eno2 -o vm-atm10 -d 10.0.0.2 -p tcp --dport 25565 -j ACCEPT 2>/dev/null \
        || iptables -I FORWARD -i eno2 -o vm-atm10 -d 10.0.0.2 -p tcp --dport 25565 -j ACCEPT
    '';
  };

  networking.nat = {
    enable = true;
    internalInterfaces = ["vm-atm10"];
    externalInterface = "eno2";
  };

  microvm.vms.atm10-vm = {
    autostart = true;
    config = {pkgs, ...}: {
      imports = [mcServers];

      microvm = {
        hypervisor = "cloud-hypervisor";
        vcpu = 8;
        mem = 21504; # JVM heap + non-heap + guest OS
        shares = [
          {
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/store";
            proto = "virtiofs";
            # Immutable and read-only → cache aggressively, sparing the per-file
            # round-trips when switch-root reads the stage-2 closure.
            readOnly = true;
            cache = "always";
          }
          {
            tag = "atm10-data";
            source = dataDir;
            mountPoint = dataDir;
            proto = "virtiofs";
            # Left at the default `cache = "auto"` (not `always` like the store): host
            # and guest both touch this, so it needs close-to-open coherence for
            # host-side config edits.
          }
        ];
        interfaces = [
          {
            type = "tap";
            id = "vm-atm10";
            mac = "02:00:00:00:0a:01";
          }
        ];
        # vsock is the `microvm -s` login. NB: setting the cid also arms microvm.nix's
        # notify relay (the boot killer) — neutralised in the host dropin below (#474).
        vsock.cid = 42;
        vsock.ssh.enable = true;

        # Boot output on the paravirtual console; the emulated 8250 serial is slow
        # enough to throttle the boot's console writes (microvm.nix#366).
        cloud-hypervisor.extraArgs = ["--console" "tty" "--serial" "off"];
      };

      boot.kernelParams = ["console=hvc0"]; # paired with --serial off above

      services.minecraft-servers = {
        enable = true;
        servers.atm10 = {
          hardening.enable = false; # the hypervisor is the boundary; in-guest hardening is redundant
          jdk = pkgs.graalvmPackages.graalvm-oracle;
          inherit dataDir;
          port = 25565;
          autoStart = true; # the VM is the gate, so the server starts with it
        };
      };

      users.users.mc-atm10.uid = mcId;
      users.groups.mc-atm10.gid = mcGid;

      # Key-only root login for `microvm -s`, trusting just the key root presents (above).
      services.openssh.settings.PermitRootLogin = "prohibit-password";
      services.openssh.settings.PasswordAuthentication = false;
      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFm07l4E9MFmWAT3uL4iVuwjVjerF1fSv3GTQwZJKECD chris@hee-ho"
      ];

      # ed25519 only — skips the per-boot RSA keygen; safe since `microvm -s` ignores
      # the host key.
      services.openssh.hostKeys = [
        {
          type = "ed25519";
          path = "/etc/ssh/ssh_host_ed25519_key";
        }
      ];

      # Route + DNS via hee-ho's NAT for online-mode auth and player replies; wait-online
      # off so the link can't stall boot.
      systemd.network.enable = true;
      systemd.network.wait-online.enable = false;
      systemd.network.networks."10-host" = {
        matchConfig.MACAddress = "02:00:00:00:0a:01";
        address = ["10.0.0.2/30"];
        routes = [{Gateway = "10.0.0.1";}];
        networkConfig.IPv6AcceptRA = false;
      };
      networking.nameservers = ["1.1.1.1"]; # static resolv.conf — resolved off below
      services.resolved.enable = false;
      services.timesyncd.enable = false; # kvm-clock gives the host's time; no NTP

      # The host's tap + DNAT gate all access (only 25565 in, admin over vsock), and an
      # inbound firewall doesn't touch the real threat (guest outbound / a VM escape),
      # so the guest's own firewall is redundant.
      networking.firewall.enable = false;

      # Root is tmpfs, so this would rebuild the journal catalog every boot for the
      # `journalctl -x` text this headless VM never reads.
      systemd.suppressedSystemUnits = ["systemd-journal-catalog-update.service"];

      environment.systemPackages = [pkgs.ghostty.terminfo];
      environment.pathsToLink = ["/share/terminfo"];

      system.stateVersion = "26.05";
    };
  };

  # Boot fix (#474): vsock.cid arms microvm.nix's socat notify relay whose 2s timeout
  # stalls boot; Type=simple + NotifyAccess=none leaves NOTIFY_SOCKET unset so it never
  # starts. OOMScoreAdjust makes the VM the first thing the kernel sacrifices if the host
  # ever runs out of memory, so an OOM can't take down host services (sshd is already at
  # -1000, tailscaled is protected in configuration.nix).
  systemd.services."microvm@atm10-vm" = {
    overrideStrategy = "asDropin";
    serviceConfig = {
      Type = lib.mkForce "simple";
      NotifyAccess = lib.mkForce "none";
      OOMScoreAdjust = 1000;
    };
  };

  # Backups: sanoid stays an unprivileged DynamicUser taking atomic ZFS snapshots. The
  # autosave toggle needs root (the vsock socket is root-only), so it's fronted by a
  # group-gated socket: only the mc-atm10-save group may connect, sanoid is in it, and
  # the connection blocks until the root handler finishes — coherent with the snapshot,
  # and sanoid gains nothing but "toggle saves". Kernel group check, no polkit/NSS.
  users.groups.mc-atm10-save = {};
  systemd.services.sanoid.serviceConfig.SupplementaryGroups = ["mc-atm10-save"];

  systemd.sockets."mc-atm10-save" = {
    wantedBy = ["sockets.target"];
    socketConfig = {
      ListenStream = saveSock;
      SocketMode = "0660";
      SocketGroup = "mc-atm10-save";
      Accept = true;
    };
  };
  systemd.services."mc-atm10-save@" = {
    description = "atm10: toggle in-guest autosave for a coherent snapshot";
    path = [pkgs.coreutils];
    serviceConfig = {
      ExecStart = saveHandler;
      StandardInput = "socket";
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  services.sanoid = {
    enable = true;
    templates.atm10 = {
      hourly = 48; # the primary "catch it fast" window
      daily = 14;
      weekly = 4;
      monthly = 3; # pinned; sanoid keeps 6 by default otherwise
      autosnap = true;
      autoprune = true;
      force_post_snapshot_script = true; # always re-enable saving
      script_timeout = 60; # above the socat wait, so the quiesce is never killed mid-flight
    };
    datasets.${zfsDataset} = {
      useTemplate = ["atm10"];
      # socat blocks until the handler closes the connection, so the quiesce finishes
      # before the snapshot; `|| true` so a failed quiesce never blocks the snapshot.
      pre_snapshot_script = "${pkgs.writeShellScript "atm10-presnap" ''
        echo off | ${pkgs.socat}/bin/socat -t30 - UNIX-CONNECT:${saveSock} || true
      ''}";
      post_snapshot_script = "${pkgs.writeShellScript "atm10-postsnap" ''
        echo on | ${pkgs.socat}/bin/socat -t30 - UNIX-CONNECT:${saveSock} || true
      ''}";
    };
  };
}
