{
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
    ../../modules/openssh.nix
    ../../modules/tmux.nix
    ../../modules/mitigations.nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot.zfs.forceImportRoot = false;

  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = [
    pkgs.htop
    pkgs.just
    pkgs.neovim
  ];

  users.users.nixos = {
    openssh.authorizedKeys.keys = import ../../users/chris/ssh-authorized-keys.nix;
  };

  system.stateVersion = "26.05";
}
