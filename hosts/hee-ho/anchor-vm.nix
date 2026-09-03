# anchor in a microVM: the server has no authentication and no TLS — knowing a
# roomId is the whole of joining that room — so the hypervisor is the boundary
# rather than in-guest systemd hardening.
_: let
  anchorId = 800; # clear of nixpkgs' static ids and of NixOS's downward-from-999 allocation
  anchorGid = 800;
  # /var/lib is zroot/var/lib, declared and neededForBoot. hee-ho's / is tmpfs
  # and the data pool's mountpoints are pool properties this repo doesn't
  # declare, so a share source under an unmounted /media/data would land on
  # tmpfs and be lost at reboot.
  dataDir = "/var/lib/anchor-server";
  anchorServer = ../../modules/services/games/anchor-server;
in {
  my.microvmHost.vms.anchor-vm = {
    index = 1;
    forwardedTCPPorts = [43383];
    oomScoreAdjust = 500; # sacrificed after atm10, before any host service
  };

  # virtiofs passes numeric ids straight through, so the guest's service user
  # only owns its own files if the host agrees on the id. chris is in the group
  # for host-side file access.
  users.users.anchor-server = {
    uid = anchorId;
    isSystemUser = true;
    group = "anchor-server";
  };
  users.groups.anchor-server = {
    gid = anchorGid;
    members = ["chris"];
  };

  # 00-nixos.conf sorts before the 10-microvm.conf microvm.nix emits for every
  # share source, so the directory is created owned by the service user instead
  # of microvm:kvm.
  systemd.tmpfiles.rules = ["d ${dataDir} 0770 anchor-server anchor-server -"];

  microvm.vms.anchor-vm = {
    autostart = true;
    config = {pkgs, ...}: {
      imports = [anchorServer];

      microvm = {
        hypervisor = "cloud-hypervisor";
        vcpu = 2;
        mem = 1024;
        storeDiskType = "erofs";
        shares = [
          {
            tag = "anchor-data";
            source = dataDir;
            mountPoint = dataDir;
            proto = "virtiofs";
          }
        ];
        cloud-hypervisor.extraArgs = ["--console" "tty" "--serial" "off"];
      };

      boot.kernelParams = ["console=hvc0"];

      services.anchor-server = {
        enable = true;
        hardening.enable = false; # the hypervisor is the boundary; in-guest hardening is redundant
        inherit dataDir;
        autoStart = true; # the VM is the gate, so the server starts with it
      };

      users.users.anchor-server.uid = anchorId;
      users.groups.anchor-server.gid = anchorGid;

      services.openssh.settings.PermitRootLogin = "prohibit-password";
      services.openssh.settings.PasswordAuthentication = false;
      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFm07l4E9MFmWAT3uL4iVuwjVjerF1fSv3GTQwZJKECD chris@hee-ho"
      ];

      services.openssh.hostKeys = [
        {
          type = "ed25519";
          path = "/etc/ssh/ssh_host_ed25519_key";
        }
      ];

      services.timesyncd.enable = false;

      # The host's tap + DNAT gate all access (only 43383 in, admin over vsock),
      # and an inbound firewall doesn't touch the real threat (guest outbound /
      # a VM escape), so the guest's own firewall is redundant.
      networking.firewall.enable = false;

      systemd.suppressedSystemUnits = ["systemd-journal-catalog-update.service"];

      environment.systemPackages = [pkgs.ghostty.terminfo];
      environment.pathsToLink = ["/share/terminfo"];

      system.stateVersion = "26.05";
    };
  };
}
