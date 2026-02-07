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
  buildXashSdk ? true,
}:
stdenv.mkDerivation {
  pname = "xash-dedicated";
  version = "0-unstable-2026-02-07";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo = "xash3d-fwgs";
    fetchSubmodules = true;
    rev = "1c1e5c50a9d824a770aa22a3f3b49490a491de45";
    hash = "sha256-vtvcoUo+9YmgMsa7HPw90s9TQNuV0zXZdW2HdebLRls=";
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
    + lib.optionalString buildXashSdk ''
      cp -TR ${xash-sdk}/valve $out/opt/valve
    '';

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
