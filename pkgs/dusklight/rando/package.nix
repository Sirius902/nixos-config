{
  dusklight,
  fetchFromGitHub,
  lib,
  nix-update-script,
  stdenv,
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
in
  dusklight.overrideAttrs (finalAttrs: prevAttrs: {
    pname = "dusklight-rando";
    version = "0-unstable-2026-07-15";
    src = prevAttrs.src.override {
      rev = "1c59d124dceb4060cfc50228a670ec67bc6b9429";
      hash = "sha256-5CuzuyuXmIskDnRQWz/LRgpDrnFStDYVFTiq9b/jgT0=";
    };

    postPatch =
      (prevAttrs.postPatch or "")
      + ''
        # Store data under TwilitRealm/DusklightRandomizer.
        substituteInPlace include/dusk/app_info.hpp \
          --replace-fail 'AppName = "Dusklight"' 'AppName = "DusklightRandomizer"' \
          --replace-fail 'LegacyAppName = "Dusk"' 'LegacyAppName = "DusklightRandomizer"'
      '';

    preConfigure =
      (prevAttrs.preConfigure or "")
      + ''
        cp -r --no-preserve=mode ${base64pp-src} base64pp-src
        cmakeFlagsArray+=("-DFETCHCONTENT_SOURCE_DIR_BASE64PP=$PWD/base64pp-src")
      '';

    cmakeFlags =
      prevAttrs.cmakeFlags
      ++ [
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_BATTERY-EMBED" "${battery-embed-src}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_YAML-CPP" "${yaml-cpp-src}")
      ];

    postInstall =
      (prevAttrs.postInstall or "")
      + lib.optionalString stdenv.hostPlatform.isLinux ''
        mv $out/share/${finalAttrs.pname}/dusklight $out/share/${finalAttrs.pname}/dusklight-rando
        rm $out/bin/dusklight
        ln -s $out/share/${finalAttrs.pname}/dusklight-rando $out/bin/dusklight-rando

        mv $out/share/applications/dev.twilitrealm.dusk.desktop \
         $out/share/applications/dev.twilitrealm.dusk-rando.desktop

        for f in $out/share/icons/hicolor/*/apps/*dusk.png; do
          mv "$f" "''${f%dusk.png}dusk-rando.png"
        done

        substituteInPlace $out/share/applications/dev.twilitrealm.dusk-rando.desktop \
          --replace-fail "Exec=dusklight" "Exec=dusklight-rando" \
          --replace-fail "''\nName=Dusklight''\n" "''\nName=Dusklight Randomizer''\n" \
          --replace-fail "GenericName=Dusklight" "GenericName=Dusklight Randomizer" \
          --replace-fail "Icon=dev.twilitrealm.dusk" "Icon=dev.twilitrealm.dusk-rando"
      ''
      + lib.optionalString stdenv.hostPlatform.isDarwin ''
        mv $out/Applications/Dusklight.app $out/Applications/DusklightRandomizer.app
      '';

    passthru =
      (prevAttrs.passthru or {})
      // {
        updateScript = nix-update-script {
          extraArgs = [
            "--version=branch=randomizer"
            "--version-regex=(0-unstable-.*)"
          ];
        };
      };

    meta = prevAttrs.meta // {mainProgram = "dusklight-rando";};
  })
