{pkgs, ...}: {
  imports = [
    ../modules/desktop-common.nix
    ../modules/secure-boot.nix
    ../modules/documentation.nix
    ../modules/ssl-dev.nix
    ../modules/xrdp.nix
    ../modules/tailscale.nix
    ../modules/docker.nix
  ];

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  environment.systemPackages = [
    pkgs.shipwright
    pkgs._2ship2harkinian
  ];

  # Mount Steam under shared directory for VMs to access
  systemd.services."bind-media-vm-shared-steam" = {
    description = "Bind mount /media/steam to /media/vm/shared/steam";
    after = ["zfs-mount.service"];
    requires = ["zfs-mount.service"];
    wantedBy = ["local-fs.target"];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = ["${pkgs.util-linux}/bin/mount --rbind /media/steam /media/vm/shared/steam"];
      ExecStop = ["${pkgs.util-linux}/bin/umount /media/vm/shared/steam"];
      RemainAfterExit = true; # Keeps the mount active after the unit runs.
    };
  };
}
