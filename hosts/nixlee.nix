{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../modules/desktop/full.nix
    ../modules/desktop/gnome/full.nix
    ../modules/desktop/cosmic/full.nix

    ../modules/programs/xrdp/default.nix
    ../modules/programs/xrdp/gnome.nix

    ../modules/secure-boot.nix
    ../modules/documentation.nix
    ../modules/ssl-dev.nix
    ../modules/tailscale.nix
    ../modules/docker.nix
  ];

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  boot.initrd.postMountCommands = ''
    ${config.boot.zfs.package}/bin/zfs rollback -r zroot/tmp@blank
  '';

  # Disable gdm since we can only have one greeter. Use cosmic greeter instead.
  services.xserver.displayManager.gdm.enable = lib.mkForce false;

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
