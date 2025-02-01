{nixos-cosmic, ...}: {
  imports = [nixos-cosmic.nixosModules.default];

  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
}
