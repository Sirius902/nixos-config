{
  fetchFromGitHub,
  lib,
  nix-update-script,
  sequence-otrizer,
  unzip,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "ganondorfs-organ";
  version = "0-unstable-2026-06-13";

  src = fetchFromGitHub {
    owner = "GanondorfsOrgan";
    repo = "Ganondorfs-Organ";
    rev = "098f52346d8a3c096bf4b6f8aff3af5685bb2f78";
    hash = "sha256-mDEMufIDduklQPk8WSxBDCZxr383xbakau4KM/nMfec=";
  };

  nativeBuildInputs = [
    sequence-otrizer
    unzip
  ];

  buildPhase = ''
    runHook preBuild

    find data/Music -name '*.ootrs' -print0 | while IFS= read -r -d "" archive; do
      unzip -qo "$archive" -d "''${archive%.ootrs}"
    done

    SequenceOTRizer --seq-path data/Music --otr-name ganondorfsorgan

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm444 -t $out/share/ganondorfs-organ mods/ganondorfsorgan.otr
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch=main"
      "--version-regex=(0-unstable-.*)"
    ];
  };

  __structuredAttrs = true;
  strictDeps = true;
  dontConfigure = true;

  meta = {
    homepage = "https://github.com/GanondorfsOrgan/Ganondorfs-Organ";
    description = "Ganondorf's Organ";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [sirius902];
  };
}
