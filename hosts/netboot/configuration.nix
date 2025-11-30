{
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = [
    pkgs.neovim
  ];

  services.openssh.enable = true;

  users.users.nixos = {
    openssh.authorizedKeys.keys = inputs.secrets.lib.opensshKeys;
  };

  system.stateVersion = "26.05";
}
