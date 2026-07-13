{
  dusklight,
  fetchzip,
  lib,
  nix-update-script,
  stdenv,
}: let
  # The tphd branch is still on the aurora from before the dependency-version
  # rework: dawn prebuilts come from encounter/dawn-build and versions are
  # declared as plain cache variables in aurora's CMakeLists.txt.
  dawnVersion = "v20260603.191052";
  nodVersion = "v2.0.0-alpha.10";

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
in
  dusklight.overrideAttrs (finalAttrs: prevAttrs: {
    pname = "dusklight-tphd";
    version = "0-unstable-2026-07-12";
    src = prevAttrs.src.override {
      rev = "6bab72092bc0f341067e761a0fe4bc582c00ee59";
      hash = "sha256-38+3MPFAuTTxCuPMwq7oDBm+8hcXAQyCwcuAA8+w9qc=";
    };

    postPatch = ''
      sed -i '/add_subdirectory(tests)/d' extern/aurora/CMakeLists.txt

      check_version() {
        local name="$1" expected="$2" var="$3" file="$4"
        actual=$(sed -n "s/.*set($var \"\([^\"]*\)\".*/\1/p" "$file")
        if [[ "$actual" != "$expected" ]]; then
          echo "error: $name version mismatch: expected '$expected', got '$actual'"
          echo "update $name in package.nix"
          exit 1
        fi
      }
      check_version "dawn" "${dawnVersion}" \
        AURORA_DAWN_VERSION extern/aurora/CMakeLists.txt
      check_version "nod" "${nodVersion}" \
        AURORA_NOD_VERSION extern/aurora/CMakeLists.txt

      # Store data under TwilitRealm/DusklightTPHD.
      substituteInPlace include/dusk/app_info.hpp \
        --replace-fail 'AppName = "Dusklight"' 'AppName = "DusklightTPHD"' \
        --replace-fail 'LegacyAppName = "Dusk"' 'LegacyAppName = "DusklightTPHD"'
    '';

    cmakeFlags =
      lib.filter (flag: !lib.hasPrefix "-DFETCHCONTENT_SOURCE_DIR_DAWN_PREBUILT" flag) prevAttrs.cmakeFlags
      ++ [(lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_DAWN_PREBUILT" "${dawn-src}")];

    postInstall =
      (prevAttrs.postInstall or "")
      + lib.optionalString stdenv.hostPlatform.isLinux ''
        mv $out/share/${finalAttrs.pname}/dusklight $out/share/${finalAttrs.pname}/dusklight-tphd
        rm $out/bin/dusklight
        ln -s $out/share/${finalAttrs.pname}/dusklight-tphd $out/bin/dusklight-tphd

        mv $out/share/applications/dev.twilitrealm.dusk.desktop \
         $out/share/applications/dev.twilitrealm.dusk-tphd.desktop

        for f in $out/share/icons/hicolor/*/apps/*dusk.png; do
          mv "$f" "''${f%dusk.png}dusk-tphd.png"
        done

        substituteInPlace $out/share/applications/dev.twilitrealm.dusk-tphd.desktop \
          --replace-fail "Exec=dusklight" "Exec=dusklight-tphd" \
          --replace-fail "''\nName=Dusklight''\n" "''\nName=Dusklight TPHD''\n" \
          --replace-fail "GenericName=Dusklight" "GenericName=Dusklight TPHD" \
          --replace-fail "Icon=dev.twilitrealm.dusk" "Icon=dev.twilitrealm.dusk-tphd"
      ''
      + lib.optionalString stdenv.hostPlatform.isDarwin ''
        mv $out/Applications/Dusklight.app $out/Applications/DusklightTPHD.app
      '';

    passthru =
      (prevAttrs.passthru or {})
      // {
        updateScript = nix-update-script {
          extraArgs = [
            "--version=branch=tphd"
            "--version-regex=(0-unstable-.*)"
          ];
        };
      };

    meta = prevAttrs.meta // {mainProgram = "dusklight-tphd";};
  })
