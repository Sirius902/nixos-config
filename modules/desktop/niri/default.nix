{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.desktop;
in {
  # Niri is installed as a secondary session alongside `cfg.environment` —
  # pick it from the greeter's session menu at login.
  config = lib.mkIf cfg.enable {
    programs.niri.enable = true;

    environment.systemPackages = with pkgs; [
      fuzzel
    ];

    home-manager.users.chris.imports = [../../home/niri.nix];
  };
}
