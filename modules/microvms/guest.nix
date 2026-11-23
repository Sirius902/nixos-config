{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.vm;

  gateway = "10.0.2.2";

  console =
    if cfg.console == null
    then ''
      echo "this VM has no console"
      exit 1
    ''
    else ''
      if ! systemctl is-active --quiet ${cfg.console.unit}; then
        echo "waiting for ${cfg.console.unit} to start"
        while ! systemctl is-active --quiet ${cfg.console.unit}; do
          # While the guest boots, the server may still be queued behind
          # other units; after that, only a start in progress is worth
          # waiting for.
          case $(systemctl is-system-running) in
            initializing | starting) ;;
            *)
              if [ "$(systemctl show --property=ActiveState --value ${cfg.console.unit})" != activating ]; then
                echo "${cfg.console.unit} is not running"
                exit 1
              fi
              ;;
          esac
          sleep 1
        done
      fi
      # Without the FIFO, cat > would create a plain file in its place.
      [ -p ${cfg.console.input} ] || {
        echo "${cfg.console.unit} has no console input"
        exit 1
      }
      journalctl --follow --lines=50 --output=cat --unit=${cfg.console.unit} &
      cat > ${cfg.console.input}
      kill $!
    '';

  controlHandler = pkgs.writeShellScript "vm-control" ''
    read -r cmd || exit 1
    case "$cmd" in
      ping)
        echo ok
        ;;
      quiesce)
        ${cfg.quiesce}
        echo ok
        ;;
      resume)
        ${cfg.resume}
        echo ok
        ;;
      console)
        ${console}
        ;;
      *)
        echo "unknown command: $cmd"
        exit 1
        ;;
    esac
  '';
in {
  imports = [
    ../jdk.nix
    ./guest-options.nix
    ../services/games/anchor-server
    ../services/games/minecraft-servers
    ../services/games/svends
    ../services/games/synergyds
  ];

  microvm = {
    hypervisor = "cloud-hypervisor";
    # This host's store is ZFS, whose O_DIRECT alignment is the recordsize;
    # cloud-hypervisor makes that the guest's block size, which Linux rejects
    # as too large, so the store disk never appears (cloud-hypervisor#8477).
    storeDiskDirect = false;
    # Each VM has its own vsock socket on the host, so the CID never clashes.
    vsock.cid = 3;
    socket = "api.sock";
    interfaces = [];
    cloud-hypervisor.extraArgs = ["--console" "tty" "--serial" "off"];
  };

  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;
  systemd.network.networks."10-uplink" = {
    matchConfig.Type = "ether";
    address = ["10.0.2.15/24"];
    routes = [{Gateway = gateway;}];
    networkConfig = {
      LinkLocalAddressing = "no";
      IPv6AcceptRA = false;
    };
  };
  # passt sends to a guest at the source MAC of frames the guest has sent,
  # broadcasting until it has seen one, and TCP drops segments that arrive
  # broadcast, so no TCP connection reaches a guest until it has sent a frame.
  systemd.services.uplink-announce = {
    description = "Announce the guest on its uplink";
    wants = ["systemd-networkd.service"];
    after = ["systemd-networkd.service"];
    # With systemd-networkd-wait-online off, this is what
    # network-online.target waits for.
    wantedBy = ["multi-user.target" "network-online.target"];
    before = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "uplink-announce" ''
        ${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --any --operational-state=routable --timeout=30 ||
          echo "uplink not routable after 30s; announcing anyway" >&2
        dev=$(${pkgs.iproute2}/bin/ip -o route get ${gateway} | ${pkgs.gnused}/bin/sed -n 's/.* dev \([^ ]*\).*/\1/p')
        exec ${pkgs.iputils}/bin/arping -f -w 5 -I "$dev" ${gateway}
      '';
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
  networking.nameservers = ["1.1.1.1"];
  services.resolved.enable = false;
  networking.firewall.enable = false;

  # The guest's journal reaches the host's through the console. A dumb TERM
  # and no colours keep escape sequences out of it, which journalctl would
  # otherwise hide as blob data.
  boot.kernelParams = ["console=hvc0" "TERM=dumb" "SYSTEMD_COLORS=0" "systemd.show_status=error"];
  services.journald.settings.Journal = {
    ForwardToConsole = true;
    TTYPath = "/dev/hvc0";
    MaxLevelConsole = "info";
  };
  systemd.services.systemd-journald.environment.SYSTEMD_COLORS = "0";
  services.getty.enable = false;
  console.enable = false;
  # Without console.enable there is no systemd-vconsole-setup.service, which
  # systemd's own rule would still restart for every virtual console.
  services.udev.packages = lib.mkAfter [
    (pkgs.writeTextDir "lib/udev/rules.d/90-vconsole.rules" "")
  ];

  nix.enable = false;
  system.disableInstallerTools = true;
  documentation.enable = false;
  environment.defaultPackages = [];
  services.nscd.enable = false;
  system.nssModules = lib.mkForce [];
  system.switch.enable = false;
  boot.initrd.includeDefaultModules = false;
  services.logrotate.enable = false;
  services.timesyncd.enable = false;

  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    hostKeys = [
      {
        type = "ed25519";
        path = "/etc/ssh/ssh_host_ed25519_key";
      }
    ];
  };
  systemd.sockets.sshd.socketConfig.ListenStream = lib.mkForce ["vsock::22"];
  systemd.generators.systemd-ssh-generator = "/dev/null";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFm07l4E9MFmWAT3uL4iVuwjVjerF1fSv3GTQwZJKECD chris@hee-ho"
  ];
  # `vm shell` from Ghostty arrives as TERM=xterm-ghostty.
  environment.systemPackages = [pkgs.ghostty.terminfo];

  systemd.sockets.vm-control = {
    wantedBy = ["sockets.target"];
    socketConfig = {
      ListenStream = "vsock::1024";
      Accept = true;
    };
  };
  systemd.services."vm-control@".serviceConfig = {
    ExecStart = controlHandler;
    StandardInput = "socket";
    StandardOutput = "socket";
    StandardError = "journal";
  };

  # The host squashes every owner on the share to this uid and gid.
  users.users.${cfg.dataUser}.uid = 800;
  users.groups.${config.users.users.${cfg.dataUser}.group}.gid = 800;

  system.stateVersion = "26.05";
}
