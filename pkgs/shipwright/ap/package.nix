{
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
  writeTextFile,
  fixDarwinDylibNames,
  applyPatches,
  shipwright-ap,
  libopus,
  opusfile,
  libogg,
  libvorbis,
  bzip2,
  libX11,
  sdl_gamecontrollerdb,
  runCommand,
  asio,
  openssl,
  valijson,
  websocketpp,
  fetchpatch2,
  nix-update-script,
}: let
  # The following would normally get fetched at build time, or a specific version is required
  dr_libs = fetchFromGitHub {
    owner = "mackron";
    repo = "dr_libs";
    rev = "da35f9d6c7374a95353fd1df1d394d44ab66cf01";
    hash = "sha256-ydFhQ8LTYDBnRTuETtfWwIHZpRciWfqGsZC6SuViEn0=";
  };

  imgui' = applyPatches {
    src = fetchFromGitHub {
      owner = "ocornut";
      repo = "imgui";
      tag = "v1.91.9b-docking";
      hash = "sha256-mQOJ6jCN+7VopgZ61yzaCnt4R1QLrW7+47xxMhFRHLQ=";
    };
    patches = [
      "${shipwright-ap.src}/libultraship/cmake/dependencies/patches/imgui-fixes-and-config.patch"
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
    rev = "bbcbc7e3f890a5806b579361e7aa0336acd547e7";
    hash = "sha256-jRPwO1Vub0cH12YMlME6kd8zGzKmcfIrIJZYpQJeOks=";
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
      "${shipwright-ap.src}/libultraship/cmake/dependencies/patches/stormlib-optimizations.patch"
    ];
  };

  thread_pool = fetchFromGitHub {
    owner = "bshoshany";
    repo = "thread-pool";
    tag = "v4.1.0";
    hash = "sha256-zhRFEmPYNFLqQCfvdAaG5VBNle9Qm8FepIIIrT9sh88=";
  };

  metalcpp = fetchFromGitHub {
    owner = "briaguya-ai";
    repo = "single-header-metal-cpp";
    tag = "macOS13_iOS16";
    hash = "sha256-CSYIpmq478bla2xoPL/cGYKIWAeiORxyFFZr0+ixd7I";
  };

  wswrap = applyPatches {
    src = fetchFromGitHub {
      owner = "black-sliver";
      repo = "wswrap";
      rev = "47438193ec50427ee28aadf294ba57baefd9f3f1";
      hash = "sha256-WWXi/OWfaC40V+tV4JNmVM8kImozuwaiRLeSdhIf0X8=";
    };
    patches = [
      (fetchpatch2 {
        name = "boost-1_87-fix.patch";
        url = "https://github.com/Sirius902/wswrap/commit/455e50470f4b4213d654251ad5ca223370f99287.patch?full_index=1";
        hash = "sha256-pTZdM2aqSJkTm+EYpX0qAA6afmbHZDzb08rbgp39lmA=";
      })
    ];
  };

  apclientpp = fetchFromGitHub {
    owner = "black-sliver";
    repo = "apclientpp";
    rev = "65638b7479f6894eda172e603cffa79762c0ddc1";
    hash = "sha256-/pUa51tZmFL15moMO1KlX5iBmMcx/vYMhqO6PZckIPo=";
  };

  cacert = fetchurl {
    url = "https://curl.se/ca/cacert-2025-09-09.pem";
    sha256 = "sha256-8pDmrK+QSkEhQkyj691wZSeAcH4o6K+ZkiF4a4a7GXU=";
  };

  sslCertStore = runCommand "sslCertStore-dir" {} ''
    mkdir -p $out
    cp ${cacert} $out/cacert.pem
  '';
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "shipwright-ap";
    version = "0-unstable-2025-12-10";

    src = fetchFromGitHub {
      owner = "Patrick12115";
      repo = "shipwright";
      rev = "562d38c6d50dd99438b23fc205013cdce70b2ee9";
      hash = "sha256-mhzRmlF/9AqYyOm8SieHHyGPq9CDwcYxwWXrAGHvJ6A=";
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
      ../darwin-fixes.patch
      ../disable-downloading-stb_image.patch
      ./disable-openssl-check.patch
      ./sslcertstore-dir.patch
      ./app-name.patch
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
        (lib.getDev libopus)
        (lib.getDev opusfile)
        libogg
        libvorbis
        bzip2
        libX11
        asio
        openssl
        valijson
        websocketpp
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        libpulseaudio
        zenity
      ];

    cmakeFlags =
      [
        (lib.cmakeBool "BUILD_REMOTE_CONTROL" true)
        (lib.cmakeBool "NON_PORTABLE" true)
        (lib.cmakeFeature "CMAKE_INSTALL_PREFIX" "${placeholder "out"}/lib")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_DR_LIBS" "${dr_libs}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_IMGUI" "${imgui'}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_LIBGFXD" "${libgfxd}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_PRISM" "${prism}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_STORMLIB" "${stormlib'}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_THREADPOOL" "${thread_pool}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_SSLCERTSTORE" "${sslCertStore}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_ASIO" "${asio}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_WSWRAP" "${wswrap}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_APCLIENTPP" "${apclientpp}")
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_METALCPP" "${metalcpp}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_SPDLOG" "${spdlog}")
        (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_VALIJSON" "${valijson}")
      ];

    env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isDarwin "-Wno-int-conversion -Wno-implicit-int -Wno-elaborated-enum-base";

    strictDeps = true;

    dontAddPrefix = true;

    # Linking fails without this
    hardeningDisable = ["format"];

    preConfigure = ''
      mkdir stb
      cp ${stb'} ./stb/${stb'.name}
      cp ${stb_impl} ./stb/${stb_impl.name}
      substituteInPlace libultraship/cmake/dependencies/common.cmake \
        --replace-fail "\''${STB_DIR}" "$(readlink -f ./stb)"

      mkdir -p ./soh/networking
      cp ${cacert} ./soh/networking/cacert.pem
    '';

    postPatch = ''
      substituteInPlace soh/src/boot/build.c.in \
      --replace-fail "@CMAKE_PROJECT_GIT_BRANCH@" "$(cat GIT_BRANCH)" \
      --replace-fail "@CMAKE_PROJECT_GIT_COMMIT_HASH@" "$(cat GIT_COMMIT_HASH)" \
      --replace-fail "@CMAKE_PROJECT_GIT_COMMIT_TAG@" "$(cat GIT_COMMIT_TAG)"
    '';

    postBuild = ''
      port_ver=$(grep CMAKE_PROJECT_VERSION: "$PWD/CMakeCache.txt" | cut -d= -f2)
      mv ../libultraship/src/fast/shaders ../soh/assets/custom
      pushd ../OTRExporter
      python3 ./extract_assets.py -z ../build/ZAPD/ZAPD.out --norom --xml-root ../soh/assets/xml --custom-assets-path ../soh/assets/custom --custom-otr-file soh.o2r --port-ver $port_ver
      popd
    '';

    preInstall = ''
      # Cmake likes it here for its install paths
      cp ../OTRExporter/soh.o2r soh/soh.o2r
      install -Dm644 ${sdl_gamecontrollerdb}/share/gamecontrollerdb.txt gamecontrollerdb.txt
    '';

    postInstall =
      lib.optionalString stdenv.hostPlatform.isLinux ''
        mkdir -p $out/bin
        ln -s $out/lib/soh.elf $out/bin/soh-ap
        install -Dm644 ../soh/macosx/sohIcon.png $out/share/pixmaps/soh-ap.png
      ''
      + lib.optionalString stdenv.hostPlatform.isDarwin ''
        # Recreate the macOS bundle (without using cpack)
        # We mirror the structure of the bundle distributed by the project

        mkdir -p $out/Applications/soh-ap.app/Contents
        cp $src/soh/macosx/Info.plist.in $out/Applications/soh-ap.app/Contents/Info.plist
        substituteInPlace $out/Applications/soh-ap.app/Contents/Info.plist \
          --replace-fail "@CMAKE_PROJECT_VERSION@" "${finalAttrs.version}" \
          --replace-fail \
            "<string>Ship of Harkinian</string>" \
            "<string>Ship of Harkinian Archipelago</string>" \
          --replace-fail \
            "<string>com.shipofharkinian.ShipOfHarkinian</string>" \
            "<string>com.shipofharkinian.ShipOfHarkinian.Archipelago</string>" \
          --replace-fail \
            "<string>~/Library/Application Support/com.shipofharkinian.soh</string>" \
            "<string>~/Library/Application Support/com.shipofharkinian.soh-ap</string>"

        mv $out/MacOS $out/Applications/soh-ap.app/Contents/MacOS

        # "lib" contains all resources that are in "Resources" in the official bundle.
        # We move them to the right place and symlink them back to $out/lib,
        # as that's where the game expects them.
        mv $out/Resources $out/Applications/soh-ap.app/Contents/Resources
        mv $out/lib/** $out/Applications/soh-ap.app/Contents/Resources
        rm -rf $out/lib
        ln -s $out/Applications/soh-ap.app/Contents/Resources $out/lib

        # Copy icons
        cp -r ../build/macosx/soh.icns $out/Applications/soh-ap.app/Contents/Resources/soh.icns

        # TODO(Sirius902) This seems like an issue upstream in ship maybe?
        # Move gamecontrollerdb.txt to the proper place for app bundle
        install -Dm644 ${sdl_gamecontrollerdb}/share/gamecontrollerdb.txt \
          $out/Applications/soh.app/Contents/Resources/gamecontrollerdb.txt

        # Codesign (ad-hoc)
        codesign -f -s - $out/Applications/soh-ap.app/Contents/MacOS/soh
      '';

    fixupPhase = lib.optionalString stdenv.hostPlatform.isLinux ''
      runHook preFixup
      wrapProgram $out/lib/soh.elf --prefix PATH ":" ${lib.makeBinPath [zenity]}
      runHook postFixup
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "soh-ap";
        icon = "soh-ap";
        exec = "soh-ap";
        comment = finalAttrs.meta.description;
        genericName = "Ship of Harkinian (Archipelago)";
        desktopName = "soh-ap";
        categories = ["Game"];
      })
    ];

    passthru.updateScript = nix-update-script {extraArgs = ["--version=branch=Prevent-Anchor-Sync-in-AP"];};

    meta = {
      homepage = "https://github.com/HarbourMasters/Shipwright";
      description = "PC port of Ocarina of Time with modern controls, widescreen, high-resolution, and more";
      mainProgram = "soh-ap";
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
      maintainers = with lib.maintainers; [matteopacini];
      license = with lib.licenses; [
        # OTRExporter, OTRGui, ZAPDTR, libultraship
        mit
        # Ship of Harkinian itself
        unfree
      ];
    };
  })
