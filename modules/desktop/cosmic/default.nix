{nixos-cosmic, ...}: {
  imports = [nixos-cosmic.nixosModules.default];

  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  # FUTURE(Sirius902) Use https://github.com/AndreasBackx/waycorner for workspace overview hot corner?

  # FUTURE(Sirius902) Hack to fix fullscreen freezing issue.
  # https://github.com/pop-os/cosmic-comp/issues/887#issuecomment-2586099427
  environment.etc."profile.d/cosmic-temp.sh".text = ''
    export COSMIC_DISABLE_DIRECT_SCANOUT=1
  '';
}
