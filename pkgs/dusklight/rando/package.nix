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
  (dusklight.override {
    dawnVersion = "v20260618.032059";
    dawnHashes = {
      darwin = "sha256-HT+qtlLaSHyoXPrUcXgcTGa877X5YfzbxRD4bJb7i1Y=";
      linux = "sha256-GFSd573b+VQx/VmFdNQgWDd0V9ayQlcw0Zuopke12ak=";
    };
    symgenVersion = "1.3.2";
    symgenHashes = {
      darwin = "sha256-A0SDjRZ03wnBfD7t3PJuuJwzP9uF39ePaK3ENgcOzL4=";
      linux = "sha256-69YvuWI6zJQrYpVgniMG+FpzBDsKihF/IHK3Yd0I5o8=";
    };
    funchookVersion = null;
  })
  .overrideAttrs (finalAttrs: prevAttrs: {
    pname = "dusklight-rando";
    version = "0-unstable-2026-08-04";
    src = prevAttrs.src.override {
      rev = "07a4d1ec6c7d80794f6ea865774ff9f45bd7da0e";
      hash = "sha256-aosW7RwT6oUUTQlMXrjzvtLEchYZq3eOe2ddKLUtkM8=";
    };

    postPatch =
      (prevAttrs.postPatch or "")
      + ''
        # Store data under TwilitRealm/DusklightRandomizer.
        substituteInPlace src/dusk/app_info.hpp \
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
          --replace-fail "''\nName=Dusklight''\n" "''\nName=Dusklight (Randomizer)''\n" \
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
