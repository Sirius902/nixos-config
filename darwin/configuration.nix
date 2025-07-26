{
  self,
  pkgs,
  secrets,
  nix-index-database,
  ...
}: {
  imports = [
    secrets.darwinModules.default
    nix-index-database.darwinModules.nix-index
    ../modules/tmux.nix
  ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [pkgs.just];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Enable alternative shell support in nix-darwin.
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

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
