{
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64-installer.nix")
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = [
    pkgs.just
  ];

  sdImage = {
    firmwareSize = 512;
    compressImage = false;
  };

  services.openssh.enable = true;

  users.users.nixos = {
    openssh.authorizedKeys.keys = inputs.secrets.lib.opensshKeys;
  };
}
