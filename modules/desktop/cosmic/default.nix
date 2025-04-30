{
  nixos-cosmic,
  pkgs,
  ...
}: {
  imports = [nixos-cosmic.nixosModules.default];

  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;

  environment.systemPackages = [pkgs.observatory];

  systemd.packages = [pkgs.observatory];
  systemd.services.monitord.wantedBy = ["multi-user.target"];

  # FUTURE(Sirius902) Use https://github.com/AndreasBackx/waycorner for workspace overview hot corner?
}
