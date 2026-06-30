# microVM evaluation harness for atm10 — separate from the prod atm10 service, and
# careful never to disturb hee-ho's networking (remote, no physical access).
{
  inputs,
  lib,
  pkgs,
  ...
}: let
  # Pinned: uids/gids are allocated at activation, not eval, so they can't be read
  # back to give the host file-owner and the guest's runtime user a matching id.
  mcTestId = 988;
  dataDir = "/media/data/mc/servers/atm10-test";
  mcServers = ../../modules/services/games/minecraft-servers;
  killFirst = 1000; # max OOMScoreAdjust — sacrifice the test before anything else
in {
  imports = [inputs.microvm.nixosModules.host];

  # Native baseline: the same server on the existing hardened-systemd framework.
  services.minecraft-servers.servers.atm10-test = {
    autoStart = false; # never run two servers against the one shared world
    port = 25566;
    openFirewall = false; # 25566 is opened host-wide already; don't re-touch the firewall
    memoryMax = "12G"; # 8G heap + non-heap headroom
    cpuWeight = 50; # yield to prod under contention
    serviceConfig = {
      CPUAffinity = "8-15"; # leave 0-7 to prod
      OOMScoreAdjust = killFirst;
    };
  };

  users.users.mc-atm10-test.uid = mcTestId;
  users.groups.mc-atm10-test.gid = mcTestId;

  # How `microvm -s` authenticates: it's `ssh -l root` over vsock, and doas runs it as
  # root — root reads this global config, so this is what makes root present chris's
  # key (trusted in the guest below). Remove it and the login breaks.
  programs.ssh.extraConfig = ''
    Host vsock-mux/* vsock/*
      IdentityFile /home/chris/.ssh/id_ed25519
      IdentitiesOnly yes
  '';

  # NetworkManager is told to ignore the tap at runtime (nmcli, not its config) so it
  # is never reloaded — only ever touching vm-atm10, never eno2/Tailscale.
  systemd.services."atm10-test-vm-hostnet" = {
    description = "Host-side networking for atm10-test-vm (tap IP + game-port forward)";
    after = ["microvm-tap-interfaces@atm10-test-vm.service"];
    bindsTo = ["microvm-tap-interfaces@atm10-test-vm.service"];
    partOf = ["microvm@atm10-test-vm.service"];
    wantedBy = ["microvm@atm10-test-vm.service"];
    path = [pkgs.iproute2 pkgs.networkmanager pkgs.iptables];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Remove the forward when the VM stops, so host:25566 isn't shadowed while off.
      ExecStop = pkgs.writeShellScript "atm10-test-vm-forward-down" ''
        iptables -t nat -D PREROUTING -i eno2 -p tcp --dport 25566 -j DNAT --to-destination 10.0.0.2:25566 2>/dev/null || true
        iptables -D FORWARD -i eno2 -o vm-atm10 -d 10.0.0.2 -p tcp --dport 25566 -j ACCEPT 2>/dev/null || true
      '';
    };
    script = ''
      nmcli device set vm-atm10 managed no 2>/dev/null || true
      ip addr replace 10.0.0.1/30 dev vm-atm10
      ip link set vm-atm10 up

      # -C guards make this idempotent on restart; -I beats any default-drop in FORWARD.
      iptables -t nat -C PREROUTING -i eno2 -p tcp --dport 25566 -j DNAT --to-destination 10.0.0.2:25566 2>/dev/null \
        || iptables -t nat -I PREROUTING -i eno2 -p tcp --dport 25566 -j DNAT --to-destination 10.0.0.2:25566
      iptables -C FORWARD -i eno2 -o vm-atm10 -d 10.0.0.2 -p tcp --dport 25566 -j ACCEPT 2>/dev/null \
        || iptables -I FORWARD -i eno2 -o vm-atm10 -d 10.0.0.2 -p tcp --dport 25566 -j ACCEPT
    '';
  };

  # Masquerade only — the game-port DNAT is lifecycle-bound in the hostnet service
  # above, not static here, so it can't shadow host:25566 while the VM is down.
  networking.nat = {
    enable = true;
    internalInterfaces = ["vm-atm10"];
    externalInterface = "eno2";
  };

  # The microVM: the same server, isolated by the hypervisor instead of by systemd.
  microvm.vms.atm10-test-vm = {
    autostart = false;
    config = {pkgs, ...}: {
      imports = [mcServers];

      microvm = {
        hypervisor = "cloud-hypervisor";
        vcpu = 8;
        mem = 12288; # 8G heap + non-heap + guest OS
        shares = [
          {
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/store";
            proto = "virtiofs";
          }
          {
            tag = "atm10-data";
            source = dataDir;
            mountPoint = dataDir;
            proto = "virtiofs";
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
      };

      services.minecraft-servers = {
        enable = true;
        servers.atm10-test = {
          hardening.enable = false; # the hypervisor is the boundary; in-guest hardening is redundant
          jdk = pkgs.graalvmPackages.graalvm-oracle;
          dataDir = dataDir;
          port = 25566;
          autoStart = true; # the VM is the manual gate, so the server starts with it
        };
      };

      # Same id as the host so virtiofs file ownership lines up.
      users.users.mc-atm10-test.uid = mcTestId;
      users.groups.mc-atm10-test.gid = mcTestId;

      # Key-only root login for `microvm -s`, trusting just the key root presents (above).
      services.openssh.settings.PermitRootLogin = "prohibit-password";
      services.openssh.settings.PasswordAuthentication = false;
      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFm07l4E9MFmWAT3uL4iVuwjVjerF1fSv3GTQwZJKECD chris@hee-ho"
      ];

      # ed25519 only — skips the ~0.7s per-boot RSA keygen; safe since `microvm -s`
      # ignores the host key.
      services.openssh.hostKeys = [
        {
          type = "ed25519";
          path = "/etc/ssh/ssh_host_ed25519_key";
        }
      ];

      # Route + DNS via hee-ho's NAT for online-mode auth and player replies;
      # wait-online off so the link can't stall boot.
      systemd.network.enable = true;
      systemd.network.wait-online.enable = false;
      systemd.network.networks."10-host" = {
        matchConfig.MACAddress = "02:00:00:00:0a:01";
        address = ["10.0.0.2/30"];
        routes = [{Gateway = "10.0.0.1";}];
        networkConfig.IPv6AcceptRA = false;
      };
      networking.nameservers = ["1.1.1.1"];

      # Only the game port — admin is over vsock, not the tap.
      networking.firewall.allowedTCPPorts = [25566];

      environment.systemPackages = with pkgs; [
        ghostty.terminfo
      ];

      environment.pathsToLink = [
        "/share/terminfo"
      ];

      system.stateVersion = "26.05";
    };
  };

  # OOMScoreAdjust: the test VM is the first thing the kernel sacrifices, never prod.
  #
  # Type/NotifyAccess is the boot fix: setting vsock.cid makes microvm.nix run a
  # `socat -T2` notify relay whose 2s timeout fires on every readiness message (~50s
  # of boot — microvm.nix#474). Type=simple + NotifyAccess=none leaves NOTIFY_SOCKET
  # unset so the relay never starts; vsock SSH is unaffected.
  systemd.services."microvm@atm10-test-vm" = {
    overrideStrategy = "asDropin";
    serviceConfig = {
      Type = lib.mkForce "simple";
      NotifyAccess = lib.mkForce "none";
      OOMScoreAdjust = killFirst;
      CPUAffinity = "8-15";
      CPUWeight = 50;
    };
  };
}
