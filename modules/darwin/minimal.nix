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

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [pkgs.just];

  nix.settings = {
    # Necessary for using flakes on this system.
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["chris"];
  };

  # Enable alternative shell support in nix-darwin.
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
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
