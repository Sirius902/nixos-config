{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.programs.steam.enable {
    programs.steam.extraCompatPackages = [pkgs.proton-wineland];
  };
}
