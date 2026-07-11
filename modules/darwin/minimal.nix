{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.home-manager.darwinModules.default
    ../home-users.nix
    ../../users/chris/darwin.nix
    ../tmux.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs;};
    users = lib.genAttrs config.my.homeUsers (_: {
      imports = [../home/ghostty/default.nix];
    });
  };

  environment.systemPackages = [pkgs.just];

  fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  nix.optimise.automatic = true;

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = 6;

  nixpkgs.hostPlatform = "aarch64-darwin";

  security.pam.services.sudo_local.touchIdAuth = true;
}
