{
  stdenv,
  lib,
  cmake,
  pkg-config,
  makeWrapper,
  fetchFromGitHub,
  fetchurl,
  fetchzip,
  runCommand,
  apple-sdk_15,
  darwinMinVersionHook,
  darwin,
  # Linux
  wayland,
  libGL,
  libX11,
  libXcursor,
  libxi,
  libxcb,
  libxrandr,
  libXScrnSaver,
  libXtst,
  libjpeg,
  libxkbcommon,
  libglvnd,
  vulkan-loader,
  # Common
  cxxopts,
  abseil-cpp,
  sdl3,
  fmt,
  tracy,
  freetype,
  zstd,
  xxhash,
  nlohmann_json,
  nix-update-script,
  # Options
  dawnVersion ? "v20260807.225922",
  dawnHashes ? {
    darwin = "sha256-pM15OoUdHZ84Y9iORsvgahE6FzvQFOtjry0nNWvIqHo=";
    linux = "sha256-deRtiZ221q6PO9zejJBwa56fCM63KEh6y2p7nM+MOYU=";
  },
  symgenVersion ? "1.3.4",
  symgenHashes ? {
    darwin = "sha256-mD72J40wvuOPJA9FHKc2/SlNoOVwXuFQKazKxcejOCk=";
    linux = "sha256-i4GgCi749d1LWa26G636ylfkcr8nJRa8EsRiXO+zdxg=";
  },
  funchookVersion ? "v1.1.3",
  funchookHash ? "sha256-u/RXMNyKL6L7p5gEFnAQTErPXXGKXv74jbYlBbG0Wy4=",
  capstoneVersion ? "4.0.2",
  capstoneHash ? "sha256-XMwQ7UaPC8YYu4yxsE4bbR3leYPfBHu5iixSLz05r3g=",
  # Revisions that predate the mods framework set this false.
  hasInTreeMods ? true,
  # Revisions that predate the borealis submodule set this false.
  hasBorealis ? true,
}: let
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
      then dawnHashes.darwin
      else dawnHashes.linux;
    stripRoot = false;
  };

  nod-src = fetchzip {
    url = let
      platform =
        if stdenv.hostPlatform.isDarwin
        then "macos-arm64"
        else "linux-x86_64";
    in "https://github.com/encounter/nod/releases/download/${nodVersion}/libnod-${platform}.tar.gz";
    hash =
      if stdenv.hostPlatform.isDarwin
      then "sha256-8ZEejxksVgShNKUVRCBYaLOp9x/qOC9pAeVrElQUGUk="
      else "sha256-FVQWECVA2gWdc+n5OQ/Tvwn8z0qdgjSd1WlFt5HKOec=";
    stripRoot = false;
  };

  imgui-src = fetchFromGitHub {
    owner = "ocornut";
    repo = "imgui";
    rev = "v1.91.9b-docking";
    hash = "sha256-mQOJ6jCN+7VopgZ61yzaCnt4R1QLrW7+47xxMhFRHLQ=";
  };

  miniz-src = fetchzip {
    url = "https://github.com/richgel999/miniz/releases/download/3.0.2/miniz-3.0.2.zip";
    hash = "sha256-DXysXkQEmoDAMMg1F8KexkwpXNyiHNzLJqXR9SMEkxk=";
    stripRoot = false;
  };

  sqlite-src = fetchzip {
    url = "https://sqlite.org/2026/sqlite-amalgamation-3510300.zip";
    hash = "sha256-pNMR8zxaaqfAzQ0AQBOXMct4usdjey1Q0Gnitg06UhM=";
  };

  rmlui-src = fetchzip {
    url = "https://github.com/mikke89/RmlUi/archive/f9b8c9e2935d5df2c7dff2c190d3968e99b0c3dc.tar.gz";
    hash = "sha256-g4O/JZUrrcseOz8o2QJRt+2CeuiLnVeuDJc906xvuIg=";
  };

  funchook-src =
    if funchookVersion == null
    then null
    else
      fetchFromGitHub {
        owner = "kubo";
        repo = "funchook";
        rev = funchookVersion;
        hash = funchookHash;
        fetchSubmodules = true;
      };

  capstone-src = fetchFromGitHub {
    owner = "capstone-engine";
    repo = "capstone";
    rev = capstoneVersion;
    hash = capstoneHash;
  };

  # `executable = true` changes a flat fetch hash to recursive mode.
  symgen-bin =
    if symgenVersion == null
    then null
    else
      fetchurl {
        url = let
          platform =
            if stdenv.hostPlatform.isDarwin
            then "macos-arm64"
            else "linux-x86_64";
        in "https://github.com/encounter/symgen/releases/download/v${symgenVersion}/symgen-${platform}";
        hash =
          if stdenv.hostPlatform.isDarwin
          then symgenHashes.darwin
          else symgenHashes.linux;
      };

  # SYMGEN_PATH does not make the downloaded release executable itself.
  symgen =
    if symgenVersion == null
    then null
    else
      runCommand "symgen-${symgenVersion}" {} ''
        install -Dm755 ${symgen-bin} $out/bin/symgen
      '';
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "dusklight";
    version = "1.4.1-unstable-2026-09-05";

    src = fetchFromGitHub {
      owner = "TwilitRealm";
      repo = "dusklight";
      rev = "58c31d304c70effe9454aa0200c578f7ac86144f";
      hash = "sha256-+xg3fEZupAlK1S5kic5qcDDwMQxE3bU9OSQlN878r1k=";
      fetchSubmodules = true;
    };

    postPatch = ''
      sed -i '/add_subdirectory(tests)/d' extern/aurora/CMakeLists.txt

      ${lib.optionalString hasInTreeMods ''
        # Each mod under mods/ is its own derivation (pkgs/dusklight/mods). CMake
        # configures every add_subdirectory regardless of what gets built, so leaving
        # them in drags the randomizer's FetchContent dependencies into the game build.
        substituteInPlace CMakeLists.txt \
          --replace-fail "if (DUSK_ENABLE_CODE_MODS AND CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)" \
            "if (FALSE)"
      ''}

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

      check_pin() {
        local name="$1" expected="$2" actual="$3"
        if [[ "$actual" != "$expected" ]]; then
          echo "error: $name version mismatch: expected '$expected', got '$actual'"
          echo "update ''${name}Version in package.nix"
          exit 1
        fi
      }
      ${lib.optionalString (symgenVersion != null) ''
        check_pin symgen "${symgenVersion}" \
          "$(sed -n 's/^set(_SYMGEN_VERSION "\([^"]*\)").*/\1/p' cmake/SymbolManifest.cmake 2>/dev/null)"
      ''}

      ${lib.optionalString (funchookVersion != null) ''
        check_pin funchook "${funchookVersion}" \
          "$(sed -n '/FetchContent_Declare(funchook/,/^ *)/s/^ *GIT_TAG *\([^ ]*\).*/\1/p' CMakeLists.txt)"

        cp -r ${funchook-src} funchook-src
        cp -r ${capstone-src} capstone-src
        chmod -R +w funchook-src capstone-src
        cmake -DSOURCE_DIR="$PWD/funchook-src" -P cmake/PatchFunchook.cmake
        substituteInPlace funchook-src/cmake/capstone.cmake.in \
          --replace-fail "GIT_REPOSITORY    https://github.com/aquynh/capstone.git" 'DOWNLOAD_COMMAND ""' \
          --replace-fail "GIT_TAG           ${capstoneVersion}" "" \
          --replace-fail 'SOURCE_DIR        "''${CMAKE_CURRENT_BINARY_DIR}/capstone-src"' "SOURCE_DIR        \"$PWD/capstone-src\""
        cmakeFlags+=("-DFETCHCONTENT_SOURCE_DIR_FUNCHOOK=$PWD/funchook-src")
      ''}

      # aurora's internal.hpp uses std::memcpy without including <cstring>.
      substituteInPlace extern/aurora/lib/internal.hpp \
        --replace-fail "#include <cstdint>" "#include <cstdint>''\n#include <cstring>"
    '';

    nativeBuildInputs =
      [
        cmake
        pkg-config
        makeWrapper
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        wayland
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        darwin.autoSignDarwinBinariesHook
        (darwinMinVersionHook "15.0")
      ];

    buildInputs =
      [
        cxxopts
        abseil-cpp
        sdl3
        fmt
        nlohmann_json
        tracy
        freetype
        zstd
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        apple-sdk_15
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        libGL
        libX11
        libXcursor
        libxi
        libxcb
        libxrandr
        libXScrnSaver
        libXtst
        libxkbcommon
        libglvnd
        vulkan-loader
      ]
      ++ [
        libjpeg
      ];

    cmakeFlags =
      [
        (lib.cmakeFeature "BOREALIS_APP_VERSION_OVERRIDE" "nix-${builtins.substring 0 7 finalAttrs.src.rev}")
        (lib.cmakeFeature "DUSK_VERSION_OVERRIDE" "nix-${builtins.substring 0 7 finalAttrs.src.rev}")
        (lib.cmakeBool "CMAKE_FIND_PACKAGE_TARGETS_GLOBAL" true)
        (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_CXXOPTS" "${cxxopts.src}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_JSON" "${nlohmann_json.src}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_MINIZ" "${miniz-src}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_DAWN_PREBUILT" "${dawn-src}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_XXHASH" "${xxhash.src}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_FMT" "${fmt.src}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_TRACY" "${tracy.src}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_NOD_PREBUILT" "${nod-src}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_FREETYPE" "${freetype.src}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_ZSTD" "${zstd.src}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_SQLITE3" "${sqlite-src}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_IMGUI" "${imgui-src}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_RMLUI" "${rmlui-src}")
        (lib.cmakeFeature "AURORA_SDL3_PROVIDER" "system")
        (lib.cmakeFeature "AURORA_NOD_PROVIDER" "package")
        (lib.cmakeBool "BUILD_SHARED_LIBS" false)
        (lib.cmakeBool "CMAKE_CROSSCOMPILING" true)
        (lib.cmakeBool "CMAKE_BUILD_WITH_INSTALL_RPATH" true)
      ]
      ++ lib.optionals (symgenVersion != null) [
        (lib.cmakeFeature "SYMGEN_PATH" "${symgen}/bin/symgen")
      ];

    # cxxopts' CXXOPTS_USE_UNICODE mode injects std::begin/end overloads for
    # icu::UnicodeString whose implicit char16_t constructor makes bool look
    # iterable to nlohmann::json's traits, breaking to_json resolution.
    env.NIX_CFLAGS_COMPILE = "-DUNISTR_FROM_CHAR_EXPLICIT=explicit";

    strictDeps = true;
    __structuredAttrs = true;

    installPhase =
      ''
        runHook preInstall
      ''
      + lib.optionalString stdenv.hostPlatform.isLinux ''
        mkdir -p $out/share/${finalAttrs.pname} $out/bin
        cp dusklight $out/share/${finalAttrs.pname}/dusklight
        cp -r ./res $out/share/${finalAttrs.pname}/res
        ln -s $out/share/${finalAttrs.pname}/dusklight $out/bin/dusklight

        install -Dm644 $src/platforms/freedesktop/dev.twilitrealm.dusk.desktop \
          $out/share/applications/dev.twilitrealm.dusk.desktop

        for size in 16 32 48 64 128 256 512 1024; do
          install -Dm644 $src/platforms/freedesktop/''${size}x''${size}/apps/dev.twilitrealm.dusk.png \
            $out/share/icons/hicolor/''${size}x''${size}/apps/dev.twilitrealm.dusk.png
        done
      ''
      + lib.optionalString stdenv.hostPlatform.isDarwin ''
        mkdir -p $out/Applications
        mv Dusklight.app $out/Applications/Dusklight.app
      ''
      + ''
        install -Dm644 -t $out/share/licenses/${finalAttrs.pname} $src/LICENSE.md
        install -Dm644 -t $out/share/licenses/${finalAttrs.pname}/aurora $src/extern/aurora/LICENSE
      ''
      + lib.optionalString hasBorealis ''
        install -Dm644 -t $out/share/licenses/${finalAttrs.pname}/borealis $src/extern/borealis/LICENSE
      ''
      + ''
        runHook postInstall
      '';

    # The bundled Dawn (WebGPU) dlopens libvulkan.so.1 / libEGL.so by soname at
    # runtime; nothing links them, so Nix's RPATH shrink drops them and the GPU
    # backends fall back to Null (no window). Re-add the loaders to the RUNPATH.
    postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
      for bin in $out/share/${finalAttrs.pname}/dusklight*; do
        patchelf --add-rpath "${lib.makeLibraryPath [vulkan-loader libglvnd]}" "$bin"
      done
    '';

    passthru.updateScript = nix-update-script {
      extraArgs = ["--version=branch"];
    };

    meta = {
      homepage = "https://github.com/TwilitRealm/dusklight";
      description = "PC port of a classic adventure game";
      mainProgram = "dusklight";
      maintainers = with lib.maintainers; [sirius902];
      platforms = ["x86_64-linux" "aarch64-darwin"];
      sourceProvenance = [
        lib.sourceTypes.fromSource
        lib.sourceTypes.binaryNativeCode
      ];
      license = with lib.licenses; [
        # extern/aurora, extern/borealis
        mit
        # Dusklight
        cc0
        # Reverse engineering
        unfree
      ];
    };
  })
