{
  dusklight,
  fetchFromGitHub,
  lib,
  nix-update-script,
  openssl,
  stdenv,
  zlib,
}: let
  base64pp-src = fetchFromGitHub {
    owner = "matheusgomes28";
    repo = "base64pp";
    rev = "v0.2.0-rc0";
    hash = "sha256-DYdnjbdZmQFOizg2SwAu35kWA0F72tE6ywe00azlqxk=";
  };

  battery-embed-src = fetchFromGitHub {
    owner = "batterycenter";
    repo = "embed";
    rev = "fdbae3f";
    hash = "sha256-yCLADGd8VITzIWr3aEt+jrzUDAKTk3YljNOuToK1zio=";
  };

  yaml-cpp-src = fetchFromGitHub {
    owner = "jbeder";
    repo = "yaml-cpp";
    rev = "yaml-cpp-0.9.0";
    hash = "sha256-+FOsPQY44h1g9tEw3O281LkiYKXdW2jnFKw+oTRkhGw=";
  };

  apcpp-src = fetchFromGitHub {
    owner = "N00byKing";
    repo = "APCpp";
    rev = "9194179d52fa4cb1ded0655c099cbc388f58833c";
    hash = "sha256-7KuW7Ajbwsl889I3ugKxY89ztcNdklMbqPiCFx4edSs=";
    fetchSubmodules = true;
  };
in
  dusklight.overrideAttrs (finalAttrs: prevAttrs: {
    pname = "dusklight-ap";
    version = "0-unstable-2026-06-09";
    src = prevAttrs.src.override {
      rev = "f6b86d3f383c557401dc536abdf7ad702794d140";
      hash = "sha256-XC8T+/yrT24WIOtMD1kjEPJ8vPewfaRq+pTi3PoRaMA=";
    };

    # APCpp's IXWebSocket needs TLS (OpenSSL) and zlib; jsoncpp is built from
    # APCpp's bundled submodule (see BUNDLED_JSONCPP below).
    buildInputs =
      prevAttrs.buildInputs
      ++ [
        openssl
        zlib
      ];

    postPatch =
      (prevAttrs.postPatch or "")
      + ''
        # Store data under TwilitRealm/DusklightArchipelago.
        substituteInPlace include/dusk/app_info.hpp \
          --replace-fail 'AppName = "Dusklight"' 'AppName = "DusklightArchipelago"' \
          --replace-fail 'LegacyAppName = "Dusk"' 'LegacyAppName = "DusklightArchipelago"'
      '';

    preConfigure =
      (prevAttrs.preConfigure or "")
      + ''
        cp -r --no-preserve=mode ${base64pp-src} base64pp-src
        cmakeFlagsArray+=("-DFETCHCONTENT_SOURCE_DIR_BASE64PP=$PWD/base64pp-src")

        # APCpp defines its library as SHARED, but it is never installed into
        # $out, so link it statically into the dusklight-ap binary instead.
        cp -r --no-preserve=mode ${apcpp-src} APCpp-src
        substituteInPlace APCpp-src/CMakeLists.txt \
          --replace-fail "add_library(APCpp SHARED" "add_library(APCpp STATIC"
        cmakeFlagsArray+=("-DFETCHCONTENT_SOURCE_DIR_APCPP=$PWD/APCpp-src")
      '';

    cmakeFlags =
      prevAttrs.cmakeFlags
      ++ [
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_BATTERY-EMBED" "${battery-embed-src}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_YAML-CPP" "${yaml-cpp-src}")
        # Use APCpp's bundled jsoncpp submodule (static) rather than a system one.
        (lib.cmakeBool "BUNDLED_JSONCPP" true)
      ];

    postInstall =
      (prevAttrs.postInstall or "")
      + lib.optionalString stdenv.hostPlatform.isLinux ''
        mv $out/share/${finalAttrs.pname}/dusklight $out/share/${finalAttrs.pname}/dusklight-ap
        rm $out/bin/dusklight
        ln -s $out/share/${finalAttrs.pname}/dusklight-ap $out/bin/dusklight-ap

        mv $out/share/applications/dev.twilitrealm.dusk.desktop \
         $out/share/applications/dev.twilitrealm.dusk-ap.desktop

        for f in $out/share/icons/hicolor/*/apps/*dusk.png; do
          mv "$f" "''${f%dusk.png}dusk-ap.png"
        done

        substituteInPlace $out/share/applications/dev.twilitrealm.dusk-ap.desktop \
          --replace-fail "Exec=dusklight" "Exec=dusklight-ap" \
          --replace-fail "''\nName=Dusklight''\n" "''\nName=Dusklight Archipelago''\n" \
          --replace-fail "GenericName=Dusklight" "GenericName=Dusklight Archipelago" \
          --replace-fail "Icon=dev.twilitrealm.dusk" "Icon=dev.twilitrealm.dusk-ap"
      ''
      + lib.optionalString stdenv.hostPlatform.isDarwin ''
        mv $out/Applications/Dusklight.app $out/Applications/DusklightArchipelago.app
      '';

    passthru =
      (prevAttrs.passthru or {})
      // {
        updateScript = nix-update-script {
          extraArgs = [
            "--version=branch=rando-archi"
            "--version-regex=(0-unstable-.*)"
          ];
        };
      };

    meta = prevAttrs.meta // {mainProgram = "dusklight-ap";};
  })
