{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../nixpkgs.nix
    inputs.impermanence.nixosModules.default
    inputs.secrets.nixosModules.default
    ../tmux.nix
    ../tailscale.nix
    ../documentation.nix
    ../openssh.nix
  ];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["chris"];
  };

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
      keepEnv = true;
      persist = true;
    }
  ];

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

  users.users.chris = {
    isNormalUser = true;
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.zsh;
  };

  programs.git.enable = true;
  programs.zsh.enable = true;
  environment.systemPackages = with pkgs; [
    fastfetch
    file
    fzf
    htop
    just
    nvd
    parted
    ripgrep
    sops
    usbutils
    xxd
  ];
}
