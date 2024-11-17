# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ isDesktop }:

{ config, inputs, pkgs, hostname, hostId, lib, ... }:

{
  imports =
    [
      inputs.secrets.nixosModules.secrets
      inputs.nix-index-database.nixosModules.nix-index
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/efi";

  # Only use kernel versions supported by ZFS.
  boot.kernelPackages =
    if (lib.versionAtLeast config.system.nixos.release "24.11")
    then pkgs.linuxPackages_6_11
    else config.boot.zfs.package.latestCompatibleLinuxPackages;

  # TODO: Remove once ZFS 2.3.0 releases.
  boot.zfs.package = pkgs.zfs_unstable;

  # Disable hibernation.
  #boot.kernelParams = [ "nohibernate" ];

  # Automatically scrub ZFS pools weekly.
  services.zfs.autoScrub.enable = true;

  security.doas.enable = true;
  security.sudo.enable = false;
  security.doas.extraRules = [{
    users = [ "chris" ];
    # Optional, retains environment variables while running commands
    # e.g. retains your NIX_PATH when applying your config
    keepEnv = true;
    persist = true; # Optional, only require password verification a single time
  }];

  networking.hostId = hostId;

  networking.hostName = hostname; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  users.users.chris = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  programs.git.enable = true;
  programs.zsh.enable = true;

  programs.nix-ld.enable = true;

  programs.kdeconnect = lib.mkIf isDesktop {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    fastfetch
    fzf
    just
    liquidctl
    lm_sensors
    nvd
    parted
    pciutils
    ripgrep
    sops
    usbutils
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
