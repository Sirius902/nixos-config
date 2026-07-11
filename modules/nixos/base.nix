{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.impermanence.nixosModules.default
    inputs.secrets.nixosModules.default
    ../../users/chris/default.nix
    ../tmux.nix
    ../tailscale.nix
    ../documentation.nix
    ../openssh.nix
    ../mitigations.nix
    ../memory.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  nix.optimise.automatic = true;

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

  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";

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

  programs.git.enable = true;
  environment.systemPackages = with pkgs; [
    fastfetch
    file
    fzf
    htop
    jq
    just
    nvd
    parted
    ripgrep
    sops
    usbutils
    xxd
  ];
}
