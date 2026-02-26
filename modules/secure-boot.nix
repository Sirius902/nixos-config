{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.secureBoot;
in {
  options.my.secureBoot.enable = lib.mkEnableOption "secure boot";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.sbctl];

    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.limine.enable = true;
    boot.loader.limine.efiSupport = true;
    boot.loader.limine.secureBoot.enable = true;
  };
}
