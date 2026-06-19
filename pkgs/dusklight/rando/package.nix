{
  dusklight,
  fetchFromGitHub,
  fetchzip,
  lib,
  nix-update-script,
  stdenv,
}: let
  # FUTURE(Sirius902) The randomizer branch still pins a pre-refactor aurora that
  # declares dawn via set(AURORA_DAWN_VERSION ...) and pulls v20260603 from
  # encounter/dawn-build, so it can't share the base package's newer dawn pinning.
  # Drop dawnVersion/dawn-src and the postPatch + cmakeFlags overrides below once
  # the randomizer branch merges the newer aurora.
  dawnVersion = "v20260603.191052";

  dawn-src = fetchzip {
    url = let
      platform =
        if stdenv.hostPlatform.isDarwin
        then "darwin-arm64"
        else "linux-x86_64";
    in "https://github.com/encounter/dawn-build/releases/download/${dawnVersion}/dawn-${platform}.tar.gz";
    hash =
      if stdenv.hostPlatform.isDarwin
      then "sha256-Uh31kwVzhabZfjqszoYDryihc29S/wideE/FuWyA9qk="
      else "sha256-yTanM4TUIv6akgpt2tai/2W6q4RAt48CxKobRgxK8WU=";
    stripRoot = false;
  };

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
    version = "0-unstable-2026-06-19";
    src = prevAttrs.src.override {
      rev = "a3de85fb4b3ac271d2f67a43bf633a911a1efdb4";
      hash = "sha256-DXDr7lxVr52MI56WA6iLY/xbQBvmECtn3pPMOK78E3E=";
    };

    # Replaces the base postPatch: its inherited check_version targets the base's
    # newer aurora (macro form, v20260618) and fails against the randomizer branch's
    # older aurora, so re-derive the steps here against this package's dawn pin.
    postPatch = ''
      sed -i '/add_subdirectory(tests)/d' extern/aurora/CMakeLists.txt

      actual=$(sed -n 's/.*AURORA_DAWN_VERSION "\([^"]*\)".*/\1/p' extern/aurora/CMakeLists.txt)
      if [[ "$actual" != "${dawnVersion}" ]]; then
        echo "error: dusklight-rando dawn mismatch: expected '${dawnVersion}', got '$actual'" >&2
        echo "the randomizer branch's aurora moved — update dawn in rando/package.nix" >&2
        exit 1
      fi

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
        # Override the base's dawn (bumped to v20260618/encounter/dawn for the newer
        # aurora) with the prebuilt this branch's aurora expects. The base sets this
        # flag too; the last -D on the CMake command line wins.
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_DAWN_PREBUILT" "${dawn-src}")
      ];

    postInstall =
      (prevAttrs.postInstall or "")
      + lib.optionalString stdenv.hostPlatform.isLinux ''
        mv $out/bin/dusklight $out/bin/dusklight-rando

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
