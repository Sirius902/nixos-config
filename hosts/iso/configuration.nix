{
  lib,
  pkgs,
  ...
}: {
  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  boot = {
    kernelPackages = pkgs.linuxPackages_6_17;
    zfs.package = pkgs.zfs_unstable;
  };

  services = {
    openssh.settings.PermitRootLogin = "yes";
  };

  users.users.root = {
    initialHashedPassword = lib.mkForce null;
    initialPassword = "nixos";
  };
}
