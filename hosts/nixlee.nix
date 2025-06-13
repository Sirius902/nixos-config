{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../modules/rollback-tmp.nix

    ../modules/desktop/full.nix
    # ../modules/desktop/gnome/full.nix
    # ../modules/desktop/ibus.nix
    ../modules/desktop/cosmic/full.nix
    # ../modules/desktop/kde/full.nix
    ../modules/desktop/fcitx.nix
    # ../modules/desktop/i3/default.nix

    ../modules/programs/xrdp/default.nix
    # ../modules/programs/xrdp/gnome.nix
    ../modules/programs/xrdp/cosmic.nix
    # ../modules/programs/xrdp/kde.nix
    # ../modules/programs/xrdp/i3.nix

    ../modules/secure-boot.nix
    ../modules/documentation.nix
    ../modules/ssl-dev.nix
    ../modules/tailscale.nix
    ../modules/docker.nix

    ../modules/pipewire/low-latency.nix

    ../modules/amd.nix
    # ../modules/nvidia.nix
  ];

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  # Disable other greeters since we can only have one.
  services.displayManager.gdm.enable = lib.mkForce false;
  # services.displayManager.cosmic-greeter.enable = lib.mkForce false;
  services.displayManager.sddm.enable = lib.mkForce false;

  services.flatpak.enable = true;

  environment.systemPackages = [
    pkgs.archipelago
    pkgs.flatpak
    pkgs.shipwright
    pkgs._2ship2harkinian
    pkgs.shipwright-anchor
    pkgs.zelda64recomp
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
