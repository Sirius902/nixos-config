{
  inputs,
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
    ../../modules/openssh.nix
    ../../modules/tmux.nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = [
    pkgs.htop
    pkgs.just
    pkgs.neovim
  ];

  users.users.nixos = {
    openssh.authorizedKeys.keys = inputs.secrets.lib.opensshKeys;
  };

  system.stateVersion = "26.05";
}
