{pkgs, ...}: {
  imports = [
    ../modules/desktop-common.nix
    ../modules/secure-boot.nix
    ../modules/documentation.nix
    ../modules/ssl-dev.nix
    ../modules/xrdp.nix
    ../modules/tailscale.nix
  ];

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  environment.systemPackages = with pkgs; [
    shipwright
  ];

  # Mount Steam under shared directory for VMs to access
  fileSystems."/media/vm/shared/steam" = {
    device = "/media/steam";
    fsType = "none";
    options = ["rbind" "x-systemd.automount"];
  };
}
