{nixos-cosmic, ...}: {
  imports = [nixos-cosmic.nixosModules.default];

  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  # FUTURE(Sirius902) Use https://github.com/AndreasBackx/waycorner for workspace overview hot corner?
}
