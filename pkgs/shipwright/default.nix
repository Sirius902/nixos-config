{
  stdenv,
  cmake,
  lsb-release,
  ninja,
  lib,
  fetchFromGitHub,
  fetchurl,
  fetchpatch,
  copyDesktopItems,
  makeDesktopItem,
  python3,
  libX11,
  libXrandr,
  libXinerama,
  libXcursor,
  libXi,
  libXext,
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
  imgui,
  stormlib,
  writeTextFile,
  libzip,
  nlohmann_json,
  spdlog,
  tinyxml-2,
}: let
  # ship needs a specific imgui version
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

  # Apply ship's patch for stormlib
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
    pname = "shipwright";
    version = "52a3058";

    src = fetchFromGitHub {
      owner = "HarbourMasters";
      repo = "shipwright";
      rev = finalAttrs.version;
      hash = "sha256-ZNIucS1HzkzG4TWjnaM7xqvdLfcaPnM8CtgVJpt9eXg=";
      fetchSubmodules = true;
    };

    # This would get fetched at build time otherwise, see:
    # https://github.com/HarbourMasters/2ship2harkinian/blob/1.0.2/mm/CMakeLists.txt#L708
    gamecontrollerdb = fetchurl {
      name = "gamecontrollerdb.txt";
      url = "https://raw.githubusercontent.com/gabomdq/SDL_GameControllerDB/eb76d847669c93ddfbc0d3556b0abebef791f8e6/gamecontrollerdb.txt";
      hash = "sha256-sIlcJL4mvRlhmvx0fe6pEu2wrFfxRDZjNaYK2H5GEZc=";
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
        name = "0002-n64-weird-frames.patch";
        url = "https://github.com/Sirius902/Shipwright/commit/28f3fed5c5596e67369139e05498eaa165e9a101.patch";
        hash = "sha256-pQybaM1ZaLdUX0gqC03RIfcGlMyeu+KxNpyAcQpdmNY=";
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
      ];

    buildInputs =
      [
        SDL2
        SDL2_net
        imgui'
        libpng
        libzip
        nlohmann_json
        spdlog
        stormlib'
        tinyxml-2
        boost.dev
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        libX11
        libXrandr
        libXinerama
        libXcursor
        libXi
        libXext
        libpulseaudio
        zenity
      ];

    cmakeFlags = [
      (lib.cmakeBool "NON_PORTABLE" true)
      (lib.cmakeFeature "CMAKE_PROJECT_VERSION" "${finalAttrs.version}")
      (lib.cmakeFeature "CMAKE_INSTALL_PREFIX" "${placeholder "out"}/soh")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_IMGUI" "${imgui'}/src")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_LIBGFXD" "${libgfxd}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_STORMLIB" "${stormlib'}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_THREADPOOL" "${thread_pool}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_PRISM" "${prism}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_DR_LIBS" "${dr_libs}")
    ];

    env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isDarwin "-Wno-int-conversion -Wno-implicit-int";

    dontAddPrefix = true;

    # Linking fails without this
    hardeningDisable = ["format"];

    preConfigure = ''
      # mirror ship's stb
      mkdir stb
      cp ${stb'} ./stb/${stb'.name}
      cp ${stb_impl} ./stb/${stb_impl.name}

      substituteInPlace libultraship/cmake/dependencies/common.cmake \
        --replace-fail "\''${STB_DIR}" "/build/source/stb"
    '';

    postBuild = ''
      cp ${finalAttrs.gamecontrollerdb} ${finalAttrs.gamecontrollerdb.name}
      ${cmake}/bin/cmake --build "$PWD" --target GenerateSohOtr
    '';

    preInstall = ''
      # Cmake likes it here for its install paths
      cp ../OTRExporter/soh.otr soh/
    '';

    postInstall =
      lib.optionalString stdenv.hostPlatform.isLinux ''
        mkdir -p $out/bin
        ln -s $out/soh/soh.elf $out/bin/soh
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

        # Wrapper
        cp $src/soh/macosx/soh-macos.sh.in $out/Applications/soh.app/Contents/MacOS/soh
        chmod +x $out/Applications/soh.app/Contents/MacOS/soh
        patchShebangs $out/Applications/soh.app/Contents/MacOS/soh

        # "soh" contains all resources that are in "Resources" in the official bundle.
        # We move them to the right place and symlink them back to $out/soh,
        # as that's where the game expects them.
        mv $out/Resources $out/Applications/soh.app/Contents/Resources
        mv $out/soh/** $out/Applications/soh.app/Contents/Resources
        rm -rf $out/soh
        ln -s $out/Applications/soh.app/Contents/Resources $out/soh

        # Copy icons
        cp -r ../build/macosx/soh.icns $out/Applications/soh.app/Contents/Resources/soh.icns

        # Fix executable
        install_name_tool -change @executable_path/../Frameworks/libSDL2-2.0.0.dylib \
                          ${SDL2}/soh/libSDL2-2.0.0.dylib \
                          $out/Applications/soh.app/Contents/Resources/soh-macos
        install_name_tool -change @executable_path/../Frameworks/libGLEW.2.2.0.dylib \
                          ${glew}/soh/libGLEW.2.2.0.dylib \
                          $out/Applications/soh.app/Contents/Resources/soh-macos
        install_name_tool -change @executable_path/../Frameworks/libpng16.16.dylib \
                          ${libpng}/soh/libpng16.16.dylib \
                          $out/Applications/soh.app/Contents/Resources/soh-macos

        # Codesign (ad-hoc)
        codesign -f -s - $out/Applications/soh.app/Contents/Resources/soh-macos
      '';

    fixupPhase = lib.optionalString stdenv.hostPlatform.isLinux ''
      wrapProgram $out/soh/soh.elf --prefix PATH ":" ${lib.makeBinPath [zenity]}
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
