{
  lib,
  jetbrains,
  openal,
  alsa-lib,
  libjack2,
  libpulseaudio,
  pipewire,
  flite,
  stdenvNoCC,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "idea-community-mc-dev";
  version = jetbrains.idea-community.version;

  nativeBuildInputs = [
    makeWrapper
    copyDesktopItems
  ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    makeWrapper ${jetbrains.idea-community}/bin/idea-community $out/bin/${finalAttrs.pname} \
      --prefix LD_LIBRARY_PATH : "${
      lib.makeLibraryPath [
        # audio
        openal
        alsa-lib
        libjack2
        libpulseaudio
        pipewire

        # text to speech
        flite
      ]
    }"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = finalAttrs.pname;
      desktopName = "IntelliJ IDEA CE (MC Dev)";
      exec = finalAttrs.meta.mainProgram;
      comment = finalAttrs.meta.description;
      categories = ["Development"];
    })
  ];

  meta = {
    description = "Script to launch Intellij with libs for Minecraft mod dev.";
    mainProgram = finalAttrs.pname;
  };
})
