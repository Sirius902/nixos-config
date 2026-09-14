{
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs) stdenv;

  mods = {
    "randomizer.dusk" = "${pkgs.dusklight-randomizer}/lib/dusklight-randomizer/randomizer.dusk";
    "cosmetics.dusk" = "${pkgs.dusklight-cosmetics}/lib/dusklight-cosmetics/cosmetics.dusk";
  };

  # Dusklight resolves its user directory with SDL_GetPrefPath under
  # XDG_DATA_HOME on Linux and Application Support on darwin; AppInfo is
  # TwilitRealm/Dusklight. The forks pin older revisions under their own
  # AppName, where these bundles have no ABI guarantee.
  modsDir =
    if stdenv.hostPlatform.isDarwin
    then "Library/Application Support/TwilitRealm/Dusklight/mods"
    else "TwilitRealm/Dusklight/mods";

  modLinks = lib.mapAttrs' (name: mod:
    lib.nameValuePair "${modsDir}/${name}" {
      source = mod;
    })
  mods;
in {
  home.packages = [pkgs.dusklight];

  # Link the bundles individually rather than the mods directory, so the loader
  # keeps wiping and recreating the extraction cache it puts alongside them.
  xdg.dataFile = lib.optionalAttrs stdenv.hostPlatform.isLinux modLinks;
  home.file = lib.optionalAttrs stdenv.hostPlatform.isDarwin modLinks;
}
