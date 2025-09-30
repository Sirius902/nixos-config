{
  apple-sdk_13,
  stdenv,
  cmake,
  lsb-release,
  ninja,
  lib,
  fetchFromGitHub,
  fetchurl,
  copyDesktopItems,
  makeDesktopItem,
  python3,
  glew,
  boost,
  SDL2,
  SDL2_net,
  pkg-config,
  libpulseaudio,
  libpng,
  imagemagick,
  zenity,
  makeWrapper,
  darwin,
  libicns,
  libzip,
  nlohmann_json,
  tinyxml-2,
  spdlog,
  libvorbis,
  libopus,
  opusfile,
  sdl_gamecontrollerdb,
  writeTextFile,
  fixDarwinDylibNames,
  applyPatches,
  nix-update-script,
  shipwright,
  fetchpatch,
}: let
  imgui' = applyPatches {
    src = fetchFromGitHub {
      owner = "ocornut";
      repo = "imgui";
      tag = "v1.91.9b-docking";
      hash = "sha256-mQOJ6jCN+7VopgZ61yzaCnt4R1QLrW7+47xxMhFRHLQ=";
    };
    patches = [
      "${shipwright.src}/libultraship/cmake/dependencies/patches/imgui-fixes-and-config.patch"
    ];
  };

  libgfxd = fetchFromGitHub {
    owner = "glankk";
    repo = "libgfxd";
    rev = "008f73dca8ebc9151b205959b17773a19c5bd0da";
    hash = "sha256-AmHAa3/cQdh7KAMFOtz5TQpcM6FqO9SppmDpKPTjTt8=";
  };

  prism = fetchFromGitHub {
    owner = "KiritoDv";
    repo = "prism-processor";
    rev = "7ae724a6fb7df8cbf547445214a1a848aefef747";
    hash = "sha256-G7koDUxD6PgZWmoJtKTNubDHg6Eoq8I+AxIJR0h3i+A=";
  };

  stb_impl = writeTextFile {
    name = "stb_impl.c";
    text = ''
      #define STB_IMAGE_IMPLEMENTATION
      #include "stb_image.h"
    '';
  };

  stb' = fetchurl {
    name = "stb_image.h";
    url = "https://raw.githubusercontent.com/nothings/stb/0bc88af4de5fb022db643c2d8e549a0927749354/stb_image.h";
    hash = "sha256-xUsVponmofMsdeLsI6+kQuPg436JS3PBl00IZ5sg3Vw=";
  };

  stormlib' = applyPatches {
    src = fetchFromGitHub {
      owner = "ladislav-zezula";
      repo = "StormLib";
      tag = "v9.25";
      hash = "sha256-HTi2FKzKCbRaP13XERUmHkJgw8IfKaRJvsK3+YxFFdc=";
    };
    patches = [
      "${shipwright.src}/libultraship/cmake/dependencies/patches/stormlib-optimizations.patch"
    ];
  };

  thread_pool = fetchFromGitHub {
    owner = "bshoshany";
    repo = "thread-pool";
    tag = "v4.1.0";
    hash = "sha256-zhRFEmPYNFLqQCfvdAaG5VBNle9Qm8FepIIIrT9sh88=";
  };

  dr_libs = fetchFromGitHub {
    owner = "mackron";
    repo = "dr_libs";
    rev = "da35f9d6c7374a95353fd1df1d394d44ab66cf01";
    hash = "sha256-ydFhQ8LTYDBnRTuETtfWwIHZpRciWfqGsZC6SuViEn0=";
  };

  metalcpp = fetchFromGitHub {
    owner = "briaguya-ai";
    repo = "single-header-metal-cpp";
    tag = "macOS13_iOS16";
    hash = "sha256-CSYIpmq478bla2xoPL/cGYKIWAeiORxyFFZr0+ixd7I";
  };
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "shipwright";
    version = "9.0.5-unstable-2025-09-30";

    src = fetchFromGitHub {
      owner = "harbourmasters";
      repo = "shipwright";
      rev = "b7de53bf8d7237c4c8ad4cd5329f3b0d62a7b0a6";
      hash = "sha256-TIPvtFvIVyPa0KZAr2kXD9NooA+4V9CdkklCEwW0uTI=";
      fetchSubmodules = true;
      deepClone = true;
      postFetch = ''
        cd $out
        git branch --show-current > GIT_BRANCH
        git rev-parse --short=7 HEAD > GIT_COMMIT_HASH
        (git describe --tags --abbrev=0 --exact-match HEAD 2>/dev/null || echo "") > GIT_COMMIT_TAG
        rm -rf .git
      '';
    };

    patches = [
      ./darwin-fixes.patch
      ./disable-downloading-stb_image.patch
      (fetchpatch {
        name = "triforce-hunt-gbk.patch";
        url = "https://github.com/Sirius902/Shipwright/commit/6bedb8c7e6f59d774d35310bb81252c054ed99b0.patch";
        hash = "sha256-1g5/j7PZiL+J+v2TjpVBTPn/e+ONsL7v+T8Xe6ZVCRs=";
      })
    ];

    nativeBuildInputs =
      [
        cmake
        ninja
        pkg-config
        python3
        imagemagick
        makeWrapper
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        lsb-release
        copyDesktopItems
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        libicns
        darwin.sigtool
        fixDarwinDylibNames
      ];

    buildInputs =
      [
        boost
        glew
        SDL2
        SDL2_net
        libpng
        libzip
        nlohmann_json
        tinyxml-2
        spdlog
        libvorbis
        libopus.dev
        opusfile.dev
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        libpulseaudio
        zenity
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        # Metal.hpp requires macOS 13.x min.
        apple-sdk_13
      ];

    cmakeFlags =
      [
        (lib.cmakeBool "BUILD_REMOTE_CONTROL" true)
        (lib.cmakeBool "NON_PORTABLE" true)
        (lib.cmakeFeature "CMAKE_INSTALL_PREFIX" "${placeholder "out"}/lib")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_IMGUI" "${imgui'}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_LIBGFXD" "${libgfxd}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_PRISM" "${prism}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_STORMLIB" "${stormlib'}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_THREADPOOL" "${thread_pool}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_DR_LIBS" "${dr_libs}")
        (lib.cmakeFeature "OPUS_INCLUDE_DIR" "${libopus.dev}/include/opus")
        (lib.cmakeFeature "OPUSFILE_INCLUDE_DIR" "${opusfile.dev}/include/opus")
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_METALCPP" "${metalcpp}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_SPDLOG" "${spdlog}")
      ];

    env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isDarwin "-Wno-int-conversion -Wno-implicit-int -Wno-elaborated-enum-base";

    dontAddPrefix = true;

    # Linking fails without this
    hardeningDisable = ["format"];

    # Pie needs to be enabled or else it segfaults
    hardeningEnable = ["pie"];

    preConfigure = ''
      mkdir stb
      cp ${stb'} ./stb/${stb'.name}
      cp ${stb_impl} ./stb/${stb_impl.name}
      substituteInPlace libultraship/cmake/dependencies/common.cmake \
        --replace-fail "\''${STB_DIR}" "$(readlink -f ./stb)"
    '';

    postPatch = ''
      substituteInPlace soh/src/boot/build.c.in \
      --replace-fail "@CMAKE_PROJECT_GIT_BRANCH@" "$(cat GIT_BRANCH)" \
      --replace-fail "@CMAKE_PROJECT_GIT_COMMIT_HASH@" "$(cat GIT_COMMIT_HASH)" \
      --replace-fail "@CMAKE_PROJECT_GIT_COMMIT_TAG@" "$(cat GIT_COMMIT_TAG)"
    '';

    postBuild = ''
      port_ver=$(grep CMAKE_PROJECT_VERSION: "$PWD/CMakeCache.txt" | cut -d= -f2)
      cp ${sdl_gamecontrollerdb}/share/gamecontrollerdb.txt gamecontrollerdb.txt
      mv ../libultraship/src/graphic/Fast3D/shaders ../soh/assets/custom
      pushd ../OTRExporter
      python3 ./extract_assets.py -z ../build/ZAPD/ZAPD.out --norom --xml-root ../soh/assets/xml --custom-assets-path ../soh/assets/custom --custom-otr-file soh.o2r --port-ver $port_ver
      popd
    '';

    preInstall = ''
      # Cmake likes it here for its install paths
      cp ../OTRExporter/soh.o2r soh/soh.o2r
    '';

    postInstall =
      lib.optionalString stdenv.hostPlatform.isLinux ''
        mkdir -p $out/bin
        ln -s $out/lib/soh.elf $out/bin/soh
        install -Dm644 ../soh/macosx/sohIcon.png $out/share/pixmaps/soh.png
      ''
      + lib.optionalString stdenv.hostPlatform.isDarwin ''
        # Recreate the macOS bundle (without using cpack)
        # We mirror the structure of the bundle distributed by the project

        mkdir -p $out/Applications/soh.app/Contents
        cp $src/soh/macosx/Info.plist.in $out/Applications/soh.app/Contents/Info.plist
        substituteInPlace $out/Applications/soh.app/Contents/Info.plist \
          --replace-fail "@CMAKE_PROJECT_VERSION@" "${finalAttrs.version}"

        mv $out/MacOS $out/Applications/soh.app/Contents/MacOS

        # "lib" contains all resources that are in "Resources" in the official bundle.
        # We move them to the right place and symlink them back to $out/lib,
        # as that's where the game expects them.
        mv $out/Resources $out/Applications/soh.app/Contents/Resources
        mv $out/lib/** $out/Applications/soh.app/Contents/Resources
        rm -rf $out/lib
        ln -s $out/Applications/soh.app/Contents/Resources $out/lib

        # TODO(Sirius902) This seems like an issue upstream in ship maybe?
        # Move gamecontrollerdb.txt to the proper place for app bundle
        cp ${sdl_gamecontrollerdb}/share/gamecontrollerdb.txt $out/Applications/soh.app/Contents/Resources/gamecontrollerdb.txt

        # Copy icons
        cp -r ../build/macosx/soh.icns $out/Applications/soh.app/Contents/Resources/soh.icns

        # Codesign (ad-hoc)
        codesign -f -s - $out/Applications/soh.app/Contents/MacOS/soh
      '';

    fixupPhase = lib.optionalString stdenv.hostPlatform.isLinux ''
      runHook preFixup
      wrapProgram $out/lib/soh.elf --prefix PATH ":" ${lib.makeBinPath [zenity]}
      runHook postFixup
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "soh";
        icon = "soh";
        exec = "soh";
        comment = finalAttrs.meta.description;
        genericName = "Ship of Harkinian";
        desktopName = "soh";
        categories = ["Game"];
      })
    ];

    passthru.updateScript = nix-update-script {extraArgs = ["--version=branch"];};

    meta = {
      homepage = "https://github.com/HarbourMasters/Shipwright";
      description = "A PC port of Ocarina of Time with modern controls, widescreen, high-resolution, and more";
      mainProgram = "soh";
      platforms = ["x86_64-linux"] ++ lib.platforms.darwin;
      maintainers = with lib.maintainers; [
        j0lol
        matteopacini
      ];
      license = with lib.licenses; [
        # OTRExporter, OTRGui, ZAPDTR, libultraship
        mit
        # Ship of Harkinian itself
        unfree
      ];
    };
  })
