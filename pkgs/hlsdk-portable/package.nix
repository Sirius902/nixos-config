{
  lib,
  fetchFromGitHub,
  stdenv,
  wafHook,
  python3,
  nix-update-script,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "hlsdk-portable";
  version = "0-unstable-2026-10-20";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo = "hlsdk-portable";
    fetchSubmodules = true;
    rev = "8a09758d2912d278423870391f6c25995de0000b";
    hash = "sha256-9Fida9wuJ77ZE9np4TTfTX5dS8O9kqgAhYuGO4bqPkw=";
  };

  nativeBuildInputs = [
    python3
    wafHook
  ];

  dontAddPrefix = true;

  wafConfigureFlags = ["-T release"] ++ lib.optionals stdenv.buildPlatform.is64bit ["-8"];

  wafInstallFlags = ["--destdir=${placeholder "out"}/lib/${finalAttrs.pname}"];

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
    maintainers = with lib.maintainers; [sirius902];
  };
})
