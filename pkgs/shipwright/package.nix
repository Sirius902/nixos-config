{
  mkShipPort,
  lib,
  fetchFromGitHub,
  nix-update-script,
}:
mkShipPort {
  pname = "shipwright";
  version = "9.1.2-unstable-2026-02-21";

  src = fetchFromGitHub {
    owner = "HarbourMasters";
    repo = "Shipwright";
    rev = "0e99b30e914b4baf910318b8ec1b1c9b2cd3aaa1";
    hash = "sha256-Ql0spUTkszJ4K1PdDGFCYBciuMKapCq4x4gRGdt3Pf8=";
    fetchSubmodules = true;
    deepClone = true;
    postFetch = ''
      cd $out
      git branch --show-current > GIT_BRANCH
      git rev-parse --short=7 HEAD > GIT_COMMIT_HASH
      (git describe --tags --abbrev=0 --exact-match HEAD 2>/dev/null || echo "") > GIT_COMMIT_TAG
      rm -rf .git
    '';
  };

  patches = [
    ./darwin-fixes.patch
    ./disable-downloading-stb_image.patch
  ];

  gameDir = "soh";
  gameBin = "soh";
  appName = "soh";
  otrFile = "soh.o2r";
  genericName = "Ship of Harkinian";
  iconSrc = "soh/macosx/sohIcon.png";
  icnsName = "soh";
  moveShaders = true;

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch"
      "--version-regex=([0-9].*)"
    ];
  };

  meta = {
    homepage = "https://github.com/HarbourMasters/Shipwright";
    description = "PC port of Ocarina of Time with modern controls, widescreen, high-resolution, and more";
    mainProgram = "soh";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = with lib.maintainers; [matteopacini];
    license = with lib.licenses; [
      # OTRExporter, OTRGui, ZAPDTR, libultraship
      mit
      # Ship of Harkinian itself
      unfree
    ];
  };
}
