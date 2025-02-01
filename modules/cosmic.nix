{
  lib,
  desktopEnv,
  ...
}:
lib.mkIf (desktopEnv == "cosmic") {
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
}
