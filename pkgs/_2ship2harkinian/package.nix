{
  mkShipPort,
  lib,
  fetchFromGitHub,
  libopus,
  opusfile,
  nix-update-script,
}:
mkShipPort {
  pname = "2ship2harkinian";
  version = "4.0.0-unstable-2026-02-22";

  src = fetchFromGitHub {
    owner = "HarbourMasters";
    repo = "2ship2harkinian";
    rev = "a5cbfdf1c4352d1ca4f89f3a35faff60ae61992d";
    hash = "sha256-3TJuZ/I+mWDE8SneoP86B/dcdkDvwOHrIiPc8kQnTYw=";
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
    ../shipwright/disable-downloading-stb_image.patch
  ];

  gameDir = "mm";
  gameBin = "2s2h";
  appName = "2s2h";
  otrFile = "2ship.o2r";
  genericName = "2 Ship 2 Harkinian";
  iconSrc = "mm/macosx/2s2hIcon.png";
  icnsName = "2s2h";

  extraCmakeFlags = [
    (lib.cmakeFeature "OPUS_INCLUDE_DIR" "${lib.getDev libopus}/include/opus")
    (lib.cmakeFeature "OPUSFILE_INCLUDE_DIR" "${lib.getDev opusfile}/include/opus")
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch"
      "--version-regex=([0-9].*)"
    ];
  };

  meta = {
    homepage = "https://github.com/HarbourMasters/2ship2harkinian";
    description = "PC port of Majora's Mask with modern controls, widescreen, high-resolution, and more";
    mainProgram = "2s2h";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = with lib.maintainers; [qubitnano];
    license = with lib.licenses; [
      # OTRExporter, OTRGui, ZAPDTR, libultraship
      mit
      # 2 Ship 2 Harkinian
      cc0
      # Reverse engineering
      unfree
    ];
  };
}
