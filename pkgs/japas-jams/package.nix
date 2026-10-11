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
  version = "0-unstable-2026-10-11";

  src = fetchFromGitHub {
    owner = "Japas-Jams";
    repo = "MM-Custom-Sequences";
    rev = "d0d0f973e8e9bef1f9797eda4ece04fac4e96650";
    hash = "sha256-iMBYjoBnLVNLgeRRLkih105KCue6/ceyme58vmTKtQ0=";
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
    install -Dm444 -t $out/share/${finalAttrs.pname} mods/japasjams.otr
    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [(python3.withPackages (ps: [ps.mpyq]))];

  installCheckPhase = ''
    runHook preInstallCheck

    python3 ${sequence-otrizer.checkOtr} sequences "$out/share/${finalAttrs.pname}/japasjams.otr"

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
    homepage = "https://github.com/Japas-Jams/MM-Custom-Sequences";
    description = "Custom Majora's Mask music sequences for 2 Ship 2 Harkinian";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [sirius902];
  };
})
