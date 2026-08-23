{
  fetchFromGitHub,
  lib,
  nix-update-script,
  sequence-otrizer,
  unzip,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "darunias-joy";
  version = "0-unstable-2026-07-15";

  src = fetchFromGitHub {
    owner = "DaruniasJoy";
    repo = "OoT-Custom-Sequences";
    rev = "19f7b2d1d4ad2a28fb56c465dcb17894a2fec5ce";
    hash = "sha256-e8TaesjMWXdAaBvFhk66YBeEjqJMI9vn8IxBga/R6gg=";
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

    SequenceOTRizer --seq-path data/Music --otr-name daruniasjoy

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm444 -t $out/share/darunias-joy mods/daruniasjoy.otr
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch=Custom-Music-2.0"
      "--version-regex=(0-unstable-.*)"
    ];
  };

  __structuredAttrs = true;
  strictDeps = true;
  dontConfigure = true;

  meta = {
    homepage = "https://github.com/DaruniasJoy/OoT-Custom-Sequences";
    description = "Darunia's Joy";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [sirius902];
  };
}
