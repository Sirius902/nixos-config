{
  fetchFromGitHub,
  lib,
  nix-update-script,
  python3,
  sequence-otrizer,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "japas-jams";
  version = "0-unstable-2026-09-13";

  src = fetchFromGitHub {
    owner = "Japas-Jams";
    repo = "MM-Custom-Sequences";
    rev = "a1997ce06bc347c6e6a1e8f43cae55d51b55cc87";
    hash = "sha256-zddAVu33Gg9GW6iU8+yRIOjSrhUyVBHcvYpqYri8Dy4=";
  };

  nativeBuildInputs = [
    python3
    sequence-otrizer
  ];

  buildPhase = ''
    runHook preBuild

    python3 ${./mmrs-to-seq.py} . sequences

    SequenceOTRizer --seq-path sequences --otr-name japasjams

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm444 -t $out/share/japas-jams mods/japasjams.otr
    runHook postInstall
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--version=branch=main"
        "--version-regex=(0-unstable-.*)"
      ];
    };

    tests.otr = sequence-otrizer.mkOtrTest {
      pack = finalAttrs.finalPackage;
      inherit (finalAttrs) src;
      otr = "share/japas-jams/japasjams.otr";
      music = "Music";
      format = ".mmrs";
    };
  };

  __structuredAttrs = true;
  strictDeps = true;
  dontConfigure = true;

  meta = {
    homepage = "https://github.com/Japas-Jams/MM-Custom-Sequences";
    description = "Japas' Jams";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [sirius902];
  };
})
