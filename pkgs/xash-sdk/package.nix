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
  version = "0-unstable-2026-02-28";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo = "hlsdk-portable";
    fetchSubmodules = true;
    rev = "6ba528f2a36622a45c453f832934ab3adaca7c1c";
    hash = "sha256-e9eM02cQv+q+eFurh9hs8eNPOidWDKg7p6WOmN7KOOY=";
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
