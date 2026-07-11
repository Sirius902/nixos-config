{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.home-manager.nixosModules.default];

  users.users.chris = {
    isNormalUser = true;
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = import ./ssh-authorized-keys.nix;
  };

  programs.zsh.enable = true;

  nix.settings.trusted-users = ["chris"];

  security.doas.extraRules = [
    {
      users = ["chris"];
      keepEnv = true;
      persist = true;
    }
  ];

  security.pam.loginLimits = [
    {
      domain = "chris";
      type = "-";
      item = "nice";
      value = "-20";
    }
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs;};
    users.chris = import ./home/default.nix;
  };
}
