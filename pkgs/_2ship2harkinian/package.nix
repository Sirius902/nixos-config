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
  writeTextFile,
  fixDarwinDylibNames,
  applyPatches,
  _2ship2harkinian,
  fetchpatch,
}: let
  # The following would normally get fetched at build time, or a specific version is required
  gamecontrollerdb = fetchFromGitHub {
    owner = "Sirius902";
    repo = "SDL_GameControllerDB";
    rev = "f7e2898a0c154eaf7508c34bfb4264104bc3f4ed";
    hash = "sha256-6J6U3sgSJegIq5ZYgWroiefxFdvv/+uDd1szBPgbtTM=";
  };

  imgui' = applyPatches {
    src = fetchFromGitHub {
      owner = "ocornut";
      repo = "imgui";
      tag = "v1.91.9b-docking";
      hash = "sha256-mQOJ6jCN+7VopgZ61yzaCnt4R1QLrW7+47xxMhFRHLQ=";
    };
    patches = [
      "${_2ship2harkinian.src}/libultraship/cmake/dependencies/patches/imgui-fixes-and-config.patch"
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
      "${_2ship2harkinian.src}/libultraship/cmake/dependencies/patches/stormlib-optimizations.patch"
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
    pname = "2ship2harkinian";
    version = "5139d60";

    src = fetchFromGitHub {
      owner = "harbourmasters";
      repo = "2ship2harkinian";
      rev = finalAttrs.version;
      hash = "sha256-AdHDGZEwtjHyjUmSkUcD+0n/qsP1n+c9I0pXgwcS3tc=";
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
      # TODO(Sirius902) Remove once underwater ocarina PR gets merged.
      (fetchpatch {
        name = "underwater-ocarina.patch";
        url = "https://github.com/Sirius902/2ship2harkinian/commit/1a2fb1da4dd974fdb462f85128101b1b51ea4f8a.patch";
        hash = "sha256-Fxr81HMUXp8Rfw71IyR5wFjdGjPuPQIW3FojMg1u6Bs=";
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
      substituteInPlace mm/src/boot/build.c.in \
      --replace-fail "@CMAKE_PROJECT_GIT_BRANCH@" "$(cat GIT_BRANCH)" \
      --replace-fail "@CMAKE_PROJECT_GIT_COMMIT_HASH@" "$(cat GIT_COMMIT_HASH)" \
      --replace-fail "@CMAKE_PROJECT_GIT_COMMIT_TAG@" "$(cat GIT_COMMIT_TAG)"
    '';

    postBuild = ''
      port_ver=$(grep CMAKE_PROJECT_VERSION: "$PWD/CMakeCache.txt" | cut -d= -f2)
      cp ${gamecontrollerdb}/gamecontrollerdb.txt gamecontrollerdb.txt
      pushd ../OTRExporter
      python3 ./extract_assets.py -z ../build/ZAPD/ZAPD.out --norom --xml-root ../mm/assets/xml --custom-assets-path ../mm/assets/custom --custom-otr-file 2ship.o2r --port-ver $port_ver
      popd
    '';

    preInstall = ''
      # Cmake likes it here for its install paths
      cp ../OTRExporter/2ship.o2r mm/2ship.o2r
    '';

    postInstall =
      lib.optionalString stdenv.hostPlatform.isLinux ''
        mkdir -p $out/bin
        ln -s $out/lib/2s2h.elf $out/bin/2s2h
        install -Dm644 ../mm/macosx/2s2hIcon.png $out/share/pixmaps/2s2h.png
      ''
      + lib.optionalString stdenv.hostPlatform.isDarwin ''
        # Recreate the macOS bundle (without using cpack)
        # We mirror the structure of the bundle distributed by the project

        mkdir -p $out/Applications/2s2h.app/Contents
        cp $src/mm/macosx/Info.plist.in $out/Applications/2s2h.app/Contents/Info.plist
        substituteInPlace $out/Applications/2s2h.app/Contents/Info.plist \
          --replace-fail "@CMAKE_PROJECT_VERSION@" "${finalAttrs.version}"

        mv $out/MacOS $out/Applications/2s2h.app/Contents/MacOS

        # "lib" contains all resources that are in "Resources" in the official bundle.
        # We move them to the right place and symlink them back to $out/lib,
        # as that's where the game expects them.
        mv $out/Resources $out/Applications/2s2h.app/Contents/Resources
        mv $out/lib/** $out/Applications/2s2h.app/Contents/Resources
        rm -rf $out/lib
        ln -s $out/Applications/2s2h.app/Contents/Resources $out/lib

        # TODO(Sirius902) This seems like an issue upstream in 2ship maybe?
        # Move gamecontrollerdb.txt to the proper place for app bundle
        cp ${gamecontrollerdb}/gamecontrollerdb.txt $out/Applications/2s2h.app/Contents/Resources/gamecontrollerdb.txt

        # Copy icons
        cp -r ../build/macosx/2s2h.icns $out/Applications/2s2h.app/Contents/Resources/2s2h.icns

        # Codesign (ad-hoc)
        codesign -f -s - $out/Applications/2s2h.app/Contents/MacOS/2s2h
      '';

    fixupPhase = lib.optionalString stdenv.hostPlatform.isLinux ''
      wrapProgram $out/lib/2s2h.elf --prefix PATH ":" ${lib.makeBinPath [zenity]}
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "2s2h";
        icon = "2s2h";
        exec = "2s2h";
        comment = finalAttrs.meta.description;
        genericName = "2 Ship 2 Harkinian";
        desktopName = "2s2h";
        categories = ["Game"];
      })
    ];

    meta = {
      homepage = "https://github.com/HarbourMasters/2ship2harkinian";
      description = "A PC port of Majora's Mask with modern controls, widescreen, high-resolution, and more";
      mainProgram = "2s2h";
      platforms = ["x86_64-linux"] ++ lib.platforms.darwin;
      maintainers = with lib.maintainers; [qubitnano];
      license = with lib.licenses; [
        # OTRExporter, OTRGui, ZAPDTR, libultraship
        mit
        # 2 Ship 2 Harkinian
        cc0
        # Reverse engineering
        unfree
      ];
    };
  })
