{
  lib,
  fetchFromGitHub,
  stdenv,
  wafHook,
  python3,
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "hlsdk-portable";
  version = "0-unstable-2026-05-25";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo = "hlsdk-portable";
    fetchSubmodules = true;
    rev = "77e18273cb2890a549ae3d6ff8016b42abbc1509";
    hash = "sha256-5bmThzk6s5mZQ6Qcu3Mxr81THcLapdo1UAFfQQiIkLc=";
  };

  nativeBuildInputs = [
    python3
    wafHook
  ];

  dontAddPrefix = true;

  wafConfigureFlags = ["-T release"] ++ lib.optionals stdenv.buildPlatform.is64bit ["-8"];

  wafInstallFlags = ["--destdir=${placeholder "out"}"];

  passthru = {
    modDir = "valve";

    updateScript = nix-update-script {
      extraArgs = [
        "--version=branch"
        "--version-regex=(0-unstable-.*)"
      ];
    };
  };

  meta = {
    homepage = "https://github.com/FWGS/hlsdk-portable";
    description = "Portable crossplatform Half-Life SDK for GoldSource and Xash3D engines";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [r4v3n6101];
  };
}
