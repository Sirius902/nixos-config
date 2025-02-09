{
  nixos-cosmic,
  pkgs,
  ...
}: {
  imports = [nixos-cosmic.nixosModules.default];

  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  # FUTURE(Sirius902) Use GNOME system monitor since COSMIC doesn't have one yet. Switch to COSMIC
  # one when/if it exists.
  environment.systemPackages = with pkgs; [gnome-system-monitor];

  # FUTURE(Sirius902) Use https://github.com/AndreasBackx/waycorner for workspace overview hot corner?
}
