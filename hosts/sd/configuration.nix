{
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64-installer.nix")
    ../../modules/openssh.nix
    ../../modules/tmux.nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = [
    pkgs.just
    pkgs.neovim
    pkgs.htop
  ];

  sdImage.compressImage = false;

  users.users.nixos = {
    openssh.authorizedKeys.keys = inputs.secrets.lib.opensshKeys;
  };

  system.stateVersion = "26.05";
}
