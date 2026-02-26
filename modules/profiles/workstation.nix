{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../nixos/standard.nix
    ../ssl-dev.nix
  ];

  my.desktop = {
    enable = true;
    full = true;
    environment = lib.mkDefault "cosmic";
    inputMethod = lib.mkDefault "fcitx";
  };

  my.gpu = lib.mkDefault "amd";
  my.xrdp.enable = lib.mkDefault true;
  my.secureBoot.enable = lib.mkDefault true;
  my.docker.enable = lib.mkDefault true;
  my.tailscale.enable = lib.mkDefault true;
  my.jdk = lib.mkDefault pkgs.graalvmPackages.graalvm-oracle;

  services.flatpak.enable = lib.mkDefault true;

  environment.systemPackages = with pkgs; [
    archipelago
    shipwright
    _2ship2harkinian
    shipwright-ap
    zelda64recomp
    waypipe
    wrye-bash
  ];
}
