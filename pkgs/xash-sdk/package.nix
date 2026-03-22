{
  lib,
  fetchFromGitHub,
  stdenv,
  wafHook,
  python3Packages,
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "xash-sdk";
  version = "0-unstable-2026-03-22";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo = "hlsdk-portable";
    fetchSubmodules = true;
    rev = "8d304faa7a33e7588cb2e0a3104c74fc89aad07e";
    hash = "sha256-j992Yhn4P+RiJV0cnH5m12rFMvKEwZVrM4yyGfLcBF4=";
  };

  nativeBuildInputs = [
    python3Packages.python
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
