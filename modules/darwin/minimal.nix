{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../nixpkgs.nix
    inputs.secrets.darwinModules.default
    inputs.nix-index-database.darwinModules.default
    ../tmux.nix

    inputs.home-manager.darwinModules.default
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = {inherit inputs;};
      home-manager.users.chris = {
        imports = [
          ../home/default.nix
          ../home/ghostty/default.nix
        ];
      };
    }
  ];

  environment.systemPackages = [pkgs.just];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["chris"];
  };

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = 5;

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.chris = {
    name = "chris";
    home = "/Users/chris";
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  programs.zsh.shellInit = ''
    export SSH_AUTH_SOCK=/Users/chris/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
  '';
}
