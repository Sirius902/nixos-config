{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.vm;

  console =
    if cfg.console == null
    then ''
      echo "this VM has no console"
      exit 1
    ''
    else ''
      if ! systemctl is-active --quiet ${cfg.console.unit}; then
        echo "${cfg.console.unit} is not running"
        exit 1
      fi
      journalctl --follow --lines=50 --output=cat --unit=${cfg.console.unit} &
      cat > ${cfg.console.input}
      kill $!
    '';

  controlHandler = pkgs.writeShellScript "vm-control" ''
    read -r cmd || exit 1
    case "$cmd" in
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
    ./guest-options.nix
    ../services/games/anchor-server
    ../services/games/minecraft-servers
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
    routes = [{Gateway = "10.0.2.2";}];
    networkConfig = {
      LinkLocalAddressing = "no";
      IPv6AcceptRA = false;
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
