{
  lib,
  fetchFromGitHub,
  stdenv,
  ensureNewerSourcesForZipFilesHook,
  python3,
  pkg-config,
  wafHook,
  xash-sdk,
  makeWrapper,
  nix-update-script,
  # Options
  sdks ? [xash-sdk],
}:
stdenv.mkDerivation {
  pname = "xash-dedicated";
  version = "0-unstable-2026-02-08";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo = "xash3d-fwgs";
    fetchSubmodules = true;
    rev = "d9221c8491761094a002dfdaff6d21aef0bc5657";
    hash = "sha256-+yheDTI2BCs6Vmpc5RUVewmQ45p8POyRUX3Oz1wh2QA=";
  };

  nativeBuildInputs = [
    ensureNewerSourcesForZipFilesHook
    python3
    pkg-config
    wafHook
    makeWrapper
  ];

  dontAddPrefix = true;

  wafConfigureFlags =
    [
      "-T release"
      "-d"
    ]
    ++ lib.optionals stdenv.buildPlatform.is64bit ["-8"];

  preInstall = ''
    mkdir -p $out/lib
  '';

  wafInstallFlags = ["--destdir=${placeholder "out"}/lib"];

  postInstall =
    ''
      mkdir -p $out/bin
      mv $out/lib/xash $out/bin/xash_ded-unwrapped
      makeWrapper $out/bin/xash_ded-unwrapped $out/bin/xash_ded \
        --set XASH3D_RODIR $out/opt \
        --run "export XASH3D_BASEDIR=\$HOME/.xash3d/" \
        --prefix ${
        if stdenv.hostPlatform.isDarwin
        then "DYLD_LIBRARY_PATH"
        else "LD_LIBRARY_PATH"
      } : "$out/lib"
    ''
    + lib.concatLines (lib.map (sdk: "cp -TR ${sdk}/${sdk.modDir} $out/opt/${sdk.modDir}") sdks);

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch"
      "--version-regex=(0-unstable-.*)"
    ];
  };

  meta = {
    homepage = "https://github.com/FWGS/xash3d-fwgs";
    description = "Xash3D FWGS dedicated server";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [r4v3n6101];
    mainProgram = "xash_ded";
  };
}
