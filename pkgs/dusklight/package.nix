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
  rev = "a85f8c203d0d68de948f7e5fd79538a226551203";

  dawnVersion = "v20260523.201736";
  nodVersion = "v2.0.0-alpha.8";

  dawn-src = fetchzip {
    url = let
      platform =
        if stdenv.hostPlatform.isDarwin
        then "darwin-arm64"
        else "linux-x86_64";
    in "https://github.com/encounter/dawn-build/releases/download/${dawnVersion}/dawn-${platform}.tar.gz";
    hash =
      if stdenv.hostPlatform.isDarwin
      then "sha256-7Y80mwxoV4kVk0ecOS02ZKTpmS0gqP7hWODZKMo9mj4="
      else "sha256-KkdlSeiaw2gbQa+phZOpgbequshxQaFITzFdiuGBZvc=";
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
      then "sha256-UPy1ywCcv0K6VJOU3uUelJuUdBh3UNaPRlyP5LOBeDw="
      else "sha256-mUqvLsbsqaZ+HAjMmHYPYO+MgtanGRTw7Gzn5uXR5rE=";
    stripRoot = false;
  };

  imgui-src = fetchFromGitHub {
    owner = "ocornut";
    repo = "imgui";
    rev = "v1.91.9b-docking";
    hash = "sha256-mQOJ6jCN+7VopgZ61yzaCnt4R1QLrW7+47xxMhFRHLQ=";
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
  stdenv.mkDerivation {
    pname = "dusklight";
    version = "0-unstable-2026-05-27";

    src = fetchFromGitHub {
      owner = "TwilitRealm";
      repo = "dusklight";
      inherit rev;
      hash = "sha256-gKcpsv12oiT1rZe6j/YfcoRQKe+VP17o0VXVKE6nkPk=";
      fetchSubmodules = true;
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
      ]
      ++ [
        libjpeg
      ];

    cmakeFlags = [
      (lib.cmakeFeature "DUSK_VERSION_OVERRIDE" "nix-${builtins.substring 0 7 rev}")
      (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_CXXOPTS" "${cxxopts.src}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_JSON" "${nlohmann_json.src}")
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
      (lib.cmakeBool "CMAKE_CROSSCOMPILING" true)
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

    passthru.updateScript = nix-update-script {
      extraArgs = [
        "--version=branch"
        "--version-regex=(0-unstable-.*)"
      ];
    };

    meta = {
      homepage = "https://github.com/TwilitRealm/dusklight";
      description = "PC port of a classic adventure game";
      mainProgram = "dusklight";
      platforms = ["x86_64-linux" "aarch64-darwin"];
      license = with lib.licenses; [unfree];
    };
  }
