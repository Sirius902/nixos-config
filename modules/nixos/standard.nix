{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./base.nix
    inputs.nix-index-database.nixosModules.default
    ../jdk.nix
    ../vfio.nix
    ../services/games/svends/default.nix
    ../desktop/default.nix
    ../gpu.nix
    ../xrdp.nix
    ../secure-boot.nix
    ../docker.nix

    inputs.home-manager.nixosModules.default
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = {inherit inputs;};
      home-manager.users.chris = import ../home/default.nix;
    }
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_6_18;
  boot.zfs.package = pkgs.zfs_unstable;

  services.zfs.autoScrub.enable = true;

  systemd.tmpfiles.rules = [
    "d /mnt 0755 root root -"
  ];

  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    drill
    liquidctl
    lm_sensors
    p7zip
    pciutils
    pv
    unzip
    wget
    zip
  ];

  system.stateVersion = "24.05";
}
