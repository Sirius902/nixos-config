{
  dusklight,
  fetchzip,
  lib,
  nix-update-script,
  stdenv,
}: let
  dawnVersion = "v20260807.225922";
  nodVersion = "v2.0.0-alpha.10";

  dawn-src = fetchzip {
    url = let
      platform =
        if stdenv.hostPlatform.isDarwin
        then "darwin-arm64"
        else "linux-x86_64";
    in "https://github.com/encounter/dawn/releases/download/${dawnVersion}/dawn-${platform}.tar.gz";
    hash =
      if stdenv.hostPlatform.isDarwin
      then "sha256-pM15OoUdHZ84Y9iORsvgahE6FzvQFOtjry0nNWvIqHo="
      else "sha256-deRtiZ221q6PO9zejJBwa56fCM63KEh6y2p7nM+MOYU=";
    stripRoot = false;
  };
in
  dusklight.overrideAttrs (finalAttrs: prevAttrs: {
    pname = "dusklight-tphd";
    version = "0-unstable-2026-08-11";
    src = prevAttrs.src.override {
      rev = "d6e4d0b58deff9c20519060493e285c13a5f1887";
      hash = "sha256-wlL7KWkG2kuuGhZeoP36MpDGMJqYA8Z14ejzS0iOSCI=";
    };

    postPatch = ''
      sed -i '/add_subdirectory(tests)/d' extern/aurora/CMakeLists.txt

      check_version() {
        local name="$1" expected="$2" var="$3"
        local file=extern/aurora/cmake/AuroraDependencyVersions.cmake
        [[ -f "$file" ]] || file=extern/aurora/CMakeLists.txt
        actual=$(sed -n "s/.*_aurora_dependency_version($var \"\([^\"]*\)\".*/\1/p" "$file")
        if [[ "$actual" != "$expected" ]]; then
          echo "error: $name version mismatch: expected '$expected', got '$actual'"
          echo "update $name in package.nix"
          exit 1
        fi
      }
      check_version "dawn" "${dawnVersion}" AURORA_DAWN_VERSION
      check_version "nod" "${nodVersion}" AURORA_NOD_VERSION

      # aurora's internal.hpp uses std::memcpy without including <cstring>.
      substituteInPlace extern/aurora/lib/internal.hpp \
        --replace-fail "#include <cstdint>" "#include <cstdint>''\n#include <cstring>"

      # Store data under TwilitRealm/DusklightTPHD.
      substituteInPlace src/dusk/app_info.hpp \
        --replace-fail '.appName = "Dusklight"' '.appName = "DusklightTPHD"' \
        --replace-fail 'AppName = "Dusklight"' 'AppName = "DusklightTPHD"'
      substituteInPlace src/dusk/data.cpp \
        --replace-fail '.appName = "Dusk"}' '.appName = "DusklightTPHD"}'
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
