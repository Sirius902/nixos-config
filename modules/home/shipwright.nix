{
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs) stdenv;

  # SequenceOTRizer names these archives and Ship keys its EnabledMods list on
  # the file stem, so the basenames are load-bearing. They are spelled out
  # rather than taken with baseNameOf because a link target may not carry the
  # store path context that would come with it.
  musicPacks = {
    "daruniasjoy.otr" = "${pkgs.darunias-joy}/share/darunias-joy/daruniasjoy.otr";
    "ganondorfsorgan.otr" = "${pkgs.ganondorfs-organ}/share/ganondorfs-organ/ganondorfsorgan.otr";
  };

  # appShortName per fork; stable.nix and ap/package.nix patch it so each gets
  # its own data directory.
  appShortNames = [
    "soh"
    "soh-stable"
    "soh-ap"
  ];

  # Ship resolves its data directory with SDL_GetPrefPath under XDG_DATA_HOME on
  # Linux, and with the SHIP_HOME that Info.plist's LSEnvironment sets on darwin.
  modsDir = appShortName:
    if stdenv.hostPlatform.isDarwin
    then "Library/Application Support/com.shipofharkinian.${appShortName}/mods"
    else "${appShortName}/mods";

  modLinks = lib.listToAttrs (lib.concatMap (appShortName:
    lib.mapAttrsToList (name: pack:
      lib.nameValuePair "${modsDir appShortName}/${name}" {
        source = pack;
      })
    musicPacks)
  appShortNames);
in {
  home.packages = [
    pkgs.shipwright
    pkgs.shipwright_stable
    pkgs.shipwright-ap
  ];

  # Link the archives individually rather than the mods directory, so the game
  # keeps writing custom_mod_files_go_here.txt and hand-dropped mods survive.
  xdg.dataFile = lib.optionalAttrs stdenv.hostPlatform.isLinux modLinks;
  home.file = lib.optionalAttrs stdenv.hostPlatform.isDarwin modLinks;
}
