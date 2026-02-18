{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # For debugging and troubleshooting Secure Boot.
    sbctl
  ];

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.limine.enable = true;
  boot.loader.limine.efiSupport = true;
  boot.loader.limine.secureBoot.enable = true;
}
