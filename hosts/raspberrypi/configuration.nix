{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.impermanence.nixosModules.impermanence
    inputs.secrets.nixosModules.default
    ./hardware-configuration.nix
    ../../modules/documentation.nix
    ../../modules/openssh.nix
    ../../modules/tailscale.nix
    ../../modules/tmux.nix
  ];

  nixpkgs = {
    overlays = [inputs.nvim-conf.overlays.default];
    config.allowUnfree = true;
  };

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["chris"];
  };

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_rpi3;
  hardware.enableRedistributableFirmware = true;

  # FUTURE(Sirius902) Rollback root + tmp via btrfs snapshots.
  environment.persistence."/persist" = {
    enable = true;
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/etc/ssh"
    ];
    files = ["/etc/machine-id"];
  };

  security.doas.enable = true;
  security.sudo.enable = false;
  security.doas.extraRules = [
    {
      users = ["chris"];
      # Optional, retains environment variables while running commands
      # e.g. retains your NIX_PATH when applying your config
      keepEnv = true;
      persist = true; # Optional, only require password verification a single time
    }
  ];

  networking.hostId = "4786fd98";
  networking.hostName = "raspberrypi"; # Define your hostname.

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
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.zsh;
  };

  programs.git.enable = true;
  programs.zsh.enable = true;
  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g default-terminal "xterm-256color"
      set-option -ga terminal-overrides ",xterm-256color:Tc"
    '';
  };

  environment.systemPackages = [
    pkgs.busybox
    pkgs.ghostty
    pkgs.just
    pkgs.nvim
    pkgs.libraspberrypi

    pkgs.fastfetch
    pkgs.file
    pkgs.fzf
    pkgs.htop
    pkgs.just
    pkgs.liquidctl
    pkgs.lm_sensors
    pkgs.nvd
    pkgs.parted
    pkgs.pciutils
    pkgs.ripgrep
    pkgs.sops
    pkgs.usbutils
    pkgs.xxd
  ];

  system.stateVersion = "26.05";
}
