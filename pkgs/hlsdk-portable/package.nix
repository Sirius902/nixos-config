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
  version = "0-unstable-2026-10-31";

  src = fetchFromGitHub {
    owner = "FWGS";
    repo = "hlsdk-portable";
    fetchSubmodules = true;
    rev = "61c3e9caec8b3f8b0a9a639c129bb527f4431d59";
    hash = "sha256-eUztYn4H6FnKFhUEFw1J/IcgXRUMZnzQeQ2RiT563S8=";
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
