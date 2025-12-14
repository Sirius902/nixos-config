{
  inputs,
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-gnome.nix")
    (modulesPath + "/installer/cd-dvd/channel.nix")
  ];

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    overlays = [inputs.nvim-conf.overlays.default];
    config.allowUnfree = true;
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  boot = {
    kernelPackages = pkgs.linuxPackages_6_18;
    zfs.package = pkgs.zfs_unstable;
  };

  environment.systemPackages = [
    pkgs.ghostty
    pkgs.just
    pkgs.nvim
    pkgs.pv
  ];

  users.users.nixos = {
    openssh.authorizedKeys.keys = inputs.secrets.lib.opensshKeys;
  };
}
