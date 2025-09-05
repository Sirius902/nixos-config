{
  lib,
  pkgs,
  stdenvNoCC,
  appimageTools,
  makeWrapper,
  xsel,
  xclip,
  mtdev,
  zenity,
  fetchurl,
  nix-update-script,
}: let
  pname = "archipelago";
  version = "0.6.3";
  src = fetchurl {
    url = "https://github.com/ArchipelagoMW/Archipelago/releases/download/${version}/Archipelago_${version}_linux-x86_64.AppImage";
    hash = "sha256-PetlGYsdhyvThIFqy+7wbPLAXDcgN2Kcl2WF3rta8PA=";
  };

  appimageContents = appimageTools.extractType2 {inherit pname version src;};
in
  stdenvNoCC.mkDerivation (finalAttrs: {
    inherit pname version src;

    dontUnpack = true;

    nativeBuildInputs = [
      makeWrapper
    ];

    runtimeDependencies =
      [
        xsel
        xclip
        mtdev
      ]
      ++ appimageTools.defaultFhsEnvArgs.targetPkgs pkgs
      ++ appimageTools.defaultFhsEnvArgs.multiPkgs pkgs;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      makeWrapper ${appimageContents}/AppRun $out/bin/archipelago \
        --set APPDIR '${appimageContents}' \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath finalAttrs.runtimeDependencies} \
        --prefix PATH : ${lib.makeBinPath [zenity]}

      install -Dm444 ${appimageContents}/archipelago.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/archipelago.desktop \
        --replace-fail 'opt/Archipelago/ArchipelagoLauncher' "archipelago"
      cp -r ${appimageContents}/usr/share/icons $out/share

      runHook postInstall
    '';

    passthru.updateScript = nix-update-script {};

    meta = {
      description = "Multi-Game Randomizer and Server";
      homepage = "https://archipelago.gg";
      changelog = "https://github.com/ArchipelagoMW/Archipelago/releases/tag/${version}";
      license = lib.licenses.mit;
      mainProgram = "archipelago";
      maintainers = with lib.maintainers; [
        pyrox0
        iqubic
      ];
      platforms = lib.platforms.linux;
    };
  })
