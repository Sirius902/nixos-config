{
  lib,
  stdenv,
  SDL2,
  cmake,
  copyDesktopItems,
  fetchFromGitHub,
  fetchpatch,
  fetchurl,
  imagemagick,
  imgui,
  libpng,
  libpulseaudio,
  libzip,
  lsb-release,
  makeDesktopItem,
  makeWrapper,
  ninja,
  nlohmann_json,
  pkg-config,
  python3,
  spdlog,
  stormlib,
  tinyxml-2,
  writeTextFile,
  zenity,
  boost,
  libvorbis,
  libopus,
  opusfile,
}: let
  # This would get fetched at build time otherwise, see:
  # https://github.com/HarbourMasters/2ship2harkinian/blob/1.0.2/mm/CMakeLists.txt#L708
  gamecontrollerdb = fetchurl {
    name = "gamecontrollerdb.txt";
    url = "https://raw.githubusercontent.com/gabomdq/SDL_GameControllerDB/f12b7db2f47a6204c09497c1d633c8a930b955fa/gamecontrollerdb.txt";
    hash = "sha256-YqNyXCqOtHT5ZHi3OnNNlSO24RuTPoMXE/hZpzOaUjs=";
  };

  # 2ship needs a specific imgui version
  imgui' = imgui.overrideAttrs (prev: rec {
    version = "1.91.6";
    src = fetchFromGitHub {
      owner = "ocornut";
      repo = "imgui";
      rev = "v${version}-docking";
      hash = "sha256-28wyzzwXE02W5vbEdRCw2iOF8ONkb3M3Al8XlYBvz1A=";
    };
    patches =
      (prev.patches or [])
      ++ [
        (fetchpatch {
          name = "imgui-fixes-and-config.patch";
          url = "https://raw.githubusercontent.com/Kenix3/libultraship/62f9df4f74bf1fc2b3daf3cfb1aa7ecd2093e893/cmake/dependencies/patches/imgui-fixes-and-config.patch";
          hash = "sha256-1DATDsKxJ3CwA3HlYiS/+q7x/cYXnonMhPH5SU4+oJ4=";
        })
      ];
    postPatch =
      (prev.postPatch or "")
      + ''
        mkdir -p $out/src
        cp -r ./* $out/src/
      '';
  });

  libgfxd = fetchFromGitHub {
    owner = "glankk";
    repo = "libgfxd";
    rev = "008f73dca8ebc9151b205959b17773a19c5bd0da";
    hash = "sha256-AmHAa3/cQdh7KAMFOtz5TQpcM6FqO9SppmDpKPTjTt8=";
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

  # Apply 2ship's patch for stormlib
  stormlib' = stormlib.overrideAttrs (prev: rec {
    version = "9.25";
    src = fetchFromGitHub {
      owner = "ladislav-zezula";
      repo = "StormLib";
      rev = "v${version}";
      hash = "sha256-HTi2FKzKCbRaP13XERUmHkJgw8IfKaRJvsK3+YxFFdc=";
    };
    nativeBuildInputs = prev.nativeBuildInputs ++ [pkg-config];
    patches =
      (prev.patches or [])
      ++ [
        (fetchpatch {
          name = "stormlib-optimizations.patch";
          url = "https://github.com/briaguya-ai/StormLib/commit/ff338b230544f8b2bb68d2fbe075175ed2fd758c.patch";
          hash = "sha256-Jbnsu5E6PkBifcx/yULMVC//ab7tszYgktS09Azs5+4=";
        })
      ];
  });

  thread_pool = fetchFromGitHub {
    owner = "bshoshany";
    repo = "thread-pool";
    rev = "v4.1.0";
    hash = "sha256-zhRFEmPYNFLqQCfvdAaG5VBNle9Qm8FepIIIrT9sh88=";
  };

  prism = fetchFromGitHub {
    owner = "KiritoDv";
    repo = "prism-processor";
    rev = "fb3f8b4a2d14dfcbae654d0f0e59a73b6f6ca850";
    hash = "sha256-gGdQSpX/TgCNZ0uyIDdnazgVHpAQhl30e+V0aVvTFMM=";
  };

  dr_libs = fetchFromGitHub {
    owner = "mackron";
    repo = "dr_libs";
    rev = "da35f9d6c7374a95353fd1df1d394d44ab66cf01";
    hash = "sha256-ydFhQ8LTYDBnRTuETtfWwIHZpRciWfqGsZC6SuViEn0=";
  };
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "2ship2harkinian";
    version = "b905115";

    src = fetchFromGitHub {
      owner = "HarbourMasters";
      repo = "2ship2harkinian";
      rev = finalAttrs.version;
      hash = "sha256-55ZEtcEYsE/Tjad0hhuUvkLzmn1UhVowC349oM7Okus=";
      fetchSubmodules = true;
    };

    patches = [
      # remove fetching stb as we will patch our own
      (fetchpatch {
        name = "0001-deps.patch";
        url = "https://raw.githubusercontent.com/NixOS/nixpkgs/e36aedc39401266c6aa5b2a9774290938a823c7d/pkgs/by-name/_2/_2ship2harkinian/0001-deps.patch";
        hash = "sha256-77nzCh/0N5EDXw7o5BoBaAiav13N+q8/geWd9ybp1Hc=";
      })
      # TODO(Sirius902) Remove once weird frames PR gets merged.
      (fetchpatch {
        name = "0002-fix-opus-include.patch";
        url = "https://github.com/Sirius902/2ship2harkinian/commit/3792abcc5f22022bc17bb58260b8ffbba552f35e.patch";
        hash = "sha256-TtdMbbzRKJKmOaMA6DCiVc5R2tBbdKejNs8jh5d+nPo=";
      })
      (fetchpatch {
        name = "0003-n64-weird-frames.patch";
        url = "https://github.com/Sirius902/2ship2harkinian/commit/ac98824ce7a299a6c7e8ed3527d826169dfe6ced.patch";
        hash = "sha256-5Z5qtIsPYgqR8JinkIjHSL8N/Hz1uVWvfN30hBg67r0=";
      })
      # TODO(Sirius902) Remove once underwater ocarina PR gets merged.
      ./0004-Enhancement-Underwater-Ocarina.patch
    ];

    nativeBuildInputs = [
      cmake
      copyDesktopItems
      imagemagick
      lsb-release
      makeWrapper
      ninja
      pkg-config
      python3
    ];

    buildInputs = [
      SDL2
      imgui'
      libpng
      libpulseaudio
      libzip
      nlohmann_json
      spdlog
      stormlib'
      tinyxml-2
      zenity
      boost
      libvorbis
      libopus.dev
      opusfile.dev
    ];

    cmakeFlags = [
      (lib.cmakeBool "NON_PORTABLE" true)
      (lib.cmakeFeature "CMAKE_PROJECT_VERSION" "${finalAttrs.version}")
      (lib.cmakeFeature "CMAKE_INSTALL_PREFIX" "${placeholder "out"}/2s2h")
      (lib.cmakeFeature "OPUS_INCLUDE_DIR" "${libopus.dev}/include/opus")
      (lib.cmakeFeature "OPUSFILE_INCLUDE_DIR" "${opusfile.dev}/include/opus")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_IMGUI" "${imgui'}/src")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_LIBGFXD" "${libgfxd}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_STORMLIB" "${stormlib'}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_THREADPOOL" "${thread_pool}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_PRISM" "${prism}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_DR_LIBS" "${dr_libs}")
    ];

    dontAddPrefix = true;

    # Linking fails without this
    hardeningDisable = ["format"];

    # Pie needs to be enabled or else it segfaults
    hardeningEnable = ["pie"];

    preConfigure = ''
      # mirror 2ship's stb
      mkdir stb
      cp ${stb'} ./stb/${stb'.name}
      cp ${stb_impl} ./stb/${stb_impl.name}

      substituteInPlace libultraship/cmake/dependencies/common.cmake \
        --replace-fail "\''${STB_DIR}" "/build/source/stb"
    '';

    postBuild = ''
      cp ${gamecontrollerdb} ${gamecontrollerdb.name}
      ${cmake}/bin/cmake --build "$PWD" --target Generate2ShipOtr
    '';

    preInstall = ''
      # Cmake likes it here for its install paths
      cp ../OTRExporter/2ship.o2r mm/
    '';

    postInstall = ''
      mkdir -p $out/bin
      ln -s $out/2s2h/2s2h.elf $out/bin/2s2h
      install -Dm644 ../mm/linux/2s2hIcon.png $out/share/pixmaps/2s2h.png
    '';

    postFixup = ''
      wrapProgram $out/2s2h/2s2h.elf --prefix PATH ":" ${lib.makeBinPath [zenity]}
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
      platforms = ["x86_64-linux"];
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
