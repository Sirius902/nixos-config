{
  mkShipPort,
  lib,
  fetchFromGitHub,
  fetchurl,
  fetchpatch2,
  applyPatches,
  runCommand,
  asio,
  openssl,
  valijson,
  websocketpp,
  nix-update-script,
}: let
  wswrap = applyPatches {
    src = fetchFromGitHub {
      owner = "black-sliver";
      repo = "wswrap";
      rev = "47438193ec50427ee28aadf294ba57baefd9f3f1";
      hash = "sha256-WWXi/OWfaC40V+tV4JNmVM8kImozuwaiRLeSdhIf0X8=";
    };
    patches = [
      (fetchpatch2 {
        name = "boost-1_87-fix.patch";
        url = "https://github.com/Sirius902/wswrap/commit/455e50470f4b4213d654251ad5ca223370f99287.patch?full_index=1";
        hash = "sha256-pTZdM2aqSJkTm+EYpX0qAA6afmbHZDzb08rbgp39lmA=";
      })
    ];
  };

  apclientpp = fetchFromGitHub {
    owner = "black-sliver";
    repo = "apclientpp";
    rev = "65638b7479f6894eda172e603cffa79762c0ddc1";
    hash = "sha256-/pUa51tZmFL15moMO1KlX5iBmMcx/vYMhqO6PZckIPo=";
  };

  cacert = fetchurl {
    url = "https://curl.se/ca/cacert-2025-09-09.pem";
    sha256 = "sha256-8pDmrK+QSkEhQkyj691wZSeAcH4o6K+ZkiF4a4a7GXU=";
  };

  sslCertStore = runCommand "sslCertStore-dir" {} ''
    mkdir -p $out
    cp ${cacert} $out/cacert.pem
  '';
in
  mkShipPort {
    pname = "shipwright-ap";
    version = "0-unstable-2026-01-22";

    src = fetchFromGitHub {
      owner = "aMannus";
      repo = "Shipwright";
      rev = "fd7ad41eec8e3b146193c9e75dbf53752749cc56";
      hash = "sha256-DH36gHW3SOlCNwwtys/Mj7m1hGU9LbJwkbkOTZ3NLKk=";
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
      ../darwin-fixes.patch
      ../disable-downloading-stb_image.patch
      ./disable-openssl-check.patch
      ./sslcertstore-dir.patch
      ./app-name.patch
    ];

    gameDir = "soh";
    gameBin = "soh";
    appName = "soh-ap";
    otrFile = "soh.o2r";
    genericName = "Ship of Harkinian (Archipelago)";
    iconSrc = "soh/macosx/sohIcon.png";
    icnsName = "soh";
    moveShaders = true;

    extraBuildInputs = [asio openssl valijson websocketpp];

    extraCmakeFlags = [
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_SSLCERTSTORE" "${sslCertStore}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_ASIO" "${asio}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_WSWRAP" "${wswrap}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_APCLIENTPP" "${apclientpp}")
    ];

    darwinExtraCmakeFlags = [
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_VALIJSON" "${valijson}")
    ];

    extraPreConfigure = ''

      mkdir -p ./soh/networking
      cp ${cacert} ./soh/networking/cacert.pem
    '';

    darwinInfoPlistExtra = ''
      substituteInPlace $out/Applications/soh-ap.app/Contents/Info.plist \
        --replace-fail \
          "<string>Ship of Harkinian</string>" \
          "<string>Ship of Harkinian Archipelago</string>" \
        --replace-fail \
          "<string>com.shipofharkinian.ShipOfHarkinian</string>" \
          "<string>com.shipofharkinian.ShipOfHarkinian.Archipelago</string>" \
        --replace-fail \
          "<string>~/Library/Application Support/com.shipofharkinian.soh</string>" \
          "<string>~/Library/Application Support/com.shipofharkinian.soh-ap</string>"
    '';

    passthru.updateScript = nix-update-script {extraArgs = ["--version=branch=aManchipelago"];};

    meta = {
      homepage = "https://github.com/HarbourMasters/Shipwright";
      description = "PC port of Ocarina of Time with modern controls, widescreen, high-resolution, and more";
      mainProgram = "soh-ap";
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
