{
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs) stdenv;

  mods = {
    "japasjams.otr" = "${pkgs.japas-jams}/share/japas-jams/japasjams.otr";
  };

  # 2 Ship resolves its data directory with SDL_GetPrefPath under XDG_DATA_HOME
  # on Linux, and with the SHIP_HOME that Info.plist's LSEnvironment sets on
  # darwin. Its appShortName is 2ship, and its bundle id is its own rather than
  # one of Ship of Harkinian's.
  modsDir =
    if stdenv.hostPlatform.isDarwin
    then "Library/Application Support/com.2ship2harkinian.2s2h/mods"
    else "2ship/mods";

  modLinks = lib.mapAttrs' (name: mod:
    lib.nameValuePair "${modsDir}/${name}" {
      source = mod;
    })
  mods;
in {
  home.packages = [pkgs._2ship2harkinian];

  # Link the archives individually rather than the mods directory, so the game
  # keeps writing custom_mod_files_go_here.txt and hand-dropped mods survive.
  xdg.dataFile = lib.optionalAttrs stdenv.hostPlatform.isLinux modLinks;
  home.file = lib.optionalAttrs stdenv.hostPlatform.isDarwin modLinks;
}
