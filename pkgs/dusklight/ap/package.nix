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
    owner = "CraftyBoss";
    repo = "APCpp";
    rev = "2d92f758269bbedaa2ec01c81b18224d2dfd2520";
    hash = "sha256-FRRxoxFQoFOpuFpUVjJybByrFjuIP+9A3QQkfEB09QE=";
    fetchSubmodules = true;
  };
in
  dusklight.overrideAttrs (finalAttrs: prevAttrs: {
    pname = "dusklight-ap";
    version = "0-unstable-2026-07-02";
    src = prevAttrs.src.override {
      rev = "589c6675fe419901782b43527bfcb11fb5808352";
      hash = "sha256-Bu6AQjIR3o79kRQERucUt5OVv33GV4N1d8hb67TaN1M=";
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
        # Uses va_start/va_copy/va_end without including <cstdarg>.
        sed -i '1i #include <cstdarg>' APCpp-src/Archipelago.cpp
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
