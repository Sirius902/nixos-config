{
  _7zz,
  fetchFromGitHub,
  lib,
  nix-update-script,
  python3,
  sequence-otrizer,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "ganondorfs-organ";
  version = "0-unstable-2026-09-13";

  src = fetchFromGitHub {
    owner = "GanondorfsOrgan";
    repo = "Ganondorfs-Organ";
    rev = "630e7ad323fe2d55d0d9dbeee10897cd9bd78c58";
    hash = "sha256-Vb7ZD1NJqKQu7FO7QsMnqlQe2SeMcCVCqpLl5TdCn6Y=";
  };

  nativeBuildInputs = [
    _7zz
    sequence-otrizer
  ];

  buildPhase = ''
    runHook preBuild

    find data/Music -name '*.ootrs' -print0 | while IFS= read -r -d "" archive; do
      7zz x -tzip -y -bso0 -bsp0 -o"''${archive%.ootrs}" "$archive"
    done

    SequenceOTRizer --seq-path data/Music --otr-name ganondorfsorgan

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm444 -t $out/share/ganondorfs-organ mods/ganondorfsorgan.otr
    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [(python3.withPackages (ps: [ps.mpyq]))];

  installCheckPhase = ''
    runHook preInstallCheck

    python3 ${sequence-otrizer.checkOtr} data/Music "$out/share/ganondorfs-organ/ganondorfsorgan.otr"

    runHook postInstallCheck
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--version=branch=main"
        "--version-regex=(0-unstable-.*)"
      ];
    };
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
