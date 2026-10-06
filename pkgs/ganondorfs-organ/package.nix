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
  version = "0-unstable-2026-10-06";

  src = fetchFromGitHub {
    owner = "GanondorfsOrgan";
    repo = "Ganondorfs-Organ";
    rev = "f31167616804109a5a70c24b6f62172e35831b77";
    hash = "sha256-/yQpIEXbPlJhiv6CDZ6sBO3p/pXVkiulE9l65us2s1U=";
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
    description = "Custom Ocarina of Time music sequences for Ship of Harkinian";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [sirius902];
  };
}
