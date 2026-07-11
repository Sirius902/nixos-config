{
  stdenv,
  lib,
  cmake,
  pkg-config,
  makeWrapper,
  fetchFromGitHub,
  fetchzip,
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
}: let
  dawnVersion = "v20260618.032059";
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
      then "sha256-HT+qtlLaSHyoXPrUcXgcTGa877X5YfzbxRD4bJb7i1Y="
      else "sha256-GFSd573b+VQx/VmFdNQgWDd0V9ayQlcw0Zuopke12ak=";
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
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "dusklight";
    version = "1.4.1-unstable-2026-07-11";

    src = fetchFromGitHub {
      owner = "TwilitRealm";
      repo = "dusklight";
      rev = "6a79bf1e7986f836e30e959eb2647803141c7c73";
      hash = "sha256-rYmSOBv80p+zwmHl1spGFrKq4x8TsEP3ZWeXCTqHlCg=";
      fetchSubmodules = true;
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

    cmakeFlags = [
      (lib.cmakeFeature "DUSK_VERSION_OVERRIDE" "nix-${builtins.substring 0 7 finalAttrs.src.rev}")
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
    ];

    strictDeps = true;
    __structuredAttrs = true;

    installPhase =
      ''
        runHook preInstall
      ''
      + lib.optionalString stdenv.hostPlatform.isLinux ''
        mkdir -p $out/bin
        cp dusklight $out/bin/dusklight
        cp -r ./res $out/bin/res

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
        runHook postInstall
      '';

    # The bundled Dawn (WebGPU) dlopens libvulkan.so.1 / libEGL.so by soname at
    # runtime; nothing links them, so Nix's RPATH shrink drops them and the GPU
    # backends fall back to Null (no window). Re-add the loaders to the RUNPATH.
    postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
      for bin in $out/bin/dusklight*; do
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
      platforms = ["x86_64-linux" "aarch64-darwin"];
      license = with lib.licenses; [unfree];
    };
  })
