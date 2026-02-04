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
  version = "0-unstable-2026-01-14";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo = "hlsdk-portable";
    fetchSubmodules = true;
    rev = "afe7d33e15c75fa61fc5a8e287bc484146e7c377";
    hash = "sha256-lR5otfTur9yRcyAt/NkcCIYcqsMg2QQ+EdkA8o18vA0=";
  };

  nativeBuildInputs = [
    python3Packages.python
    wafHook
  ];

  dontAddPrefix = true;

  wafConfigureFlags = ["-T release"] ++ lib.optionals stdenv.buildPlatform.is64bit ["-8"];

  wafInstallFlags = ["--destdir=${placeholder "out"}"];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch"
      "--version-regex=(0-unstable-.*)"
    ];
  };

  meta = {
    homepage = "https://github.com/FWGS/hlsdk-portable";
    description = "Portable crossplatform Half-Life SDK for GoldSource and Xash3D engines";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [r4v3n6101];
  };
}
