{
  config,
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

  # Configurable gaming mice (Logitech G600 etc.): ratbagctl CLI + Piper GUI
  services.ratbagd.enable = lib.mkDefault true;

  home-manager.users = lib.genAttrs config.my.homeUsers (_: {
    imports = [../home/games.nix];
  });

  environment.systemPackages = with pkgs;
    [waypipe]
    ++ lib.optional config.services.ratbagd.enable piper;
}
