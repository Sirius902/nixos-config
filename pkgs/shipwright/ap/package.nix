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
  libGL,
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
  libopus,
  opusfile,
  libogg,
  libvorbis,
  bzip2,
  libx11,
  sdl_gamecontrollerdb,
  cacert,
  runCommand,
  asio,
  openssl,
  valijson,
  websocketpp,
  fetchpatch,
  nix-update-script,
}:
stdenv.mkDerivation (finalAttrs: let
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
      "${finalAttrs.src}/libultraship/cmake/dependencies/patches/imgui-fixes-and-config.patch"
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
      "${finalAttrs.src}/libultraship/cmake/dependencies/patches/stormlib-optimizations.patch"
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
      rev = "d0505e0ec53a26743f11051949a0dc66bcf44951";
      hash = "sha256-BmRgWnIeTyH8B2kDF/7KsEy0dcoq+ckKyxzbrHdK/no=";
    };
    patches = [
      (fetchpatch {
        name = "boost-1_87-fix.patch";
        url = "https://github.com/black-sliver/wswrap/commit/455e50470f4b4213d654251ad5ca223370f99287.diff";
        hash = "sha256-aaLP2fw4s5H8X1b/N+ZiTocCZhu+U0J7hosZ1N36E9k=";
      })
    ];
  };

  apclientpp = fetchFromGitHub {
    owner = "black-sliver";
    repo = "apclientpp";
    rev = "7f33a3849887983378258c2fe8fc3887f687c430";
    hash = "sha256-y3XVvXMlK7nwKMZsgsPtdfqOBgRruU5nknZxHZZUlvY=";
  };

  sslCertStore = runCommand "sslCertStore-dir" {} ''
    mkdir -p $out
    cp ${cacert}/etc/ssl/certs/ca-bundle.crt $out/cacert.pem
  '';
in {
  pname = "shipwright-ap";
  version = "1.4.2-unstable-2026-07-04";

  src = fetchFromGitHub {
    owner = "jeromkiller";
    repo = "Shipwright_archipellago";
    rev = "96b35fd5824b706456df7ea3f34e0353865e91cd";
    hash = "sha256-qgQCQpiqEHawV/SKpWO3kZ45J91yslaWkTHypZjy3Yk=";
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
      darwin.autoSignDarwinBinariesHook
      fixDarwinDylibNames
    ];

  buildInputs =
    [
      boost
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
      libx11
      asio
      openssl
      valijson
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      libGL
      libpulseaudio
      zenity
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      glew
    ];

  cmakeFlags =
    [
      (lib.cmakeBool "BUILD_REMOTE_CONTROL" true)
      (lib.cmakeBool "NON_PORTABLE" true)
      (lib.cmakeFeature "CMAKE_INSTALL_PREFIX" "${placeholder "out"}/share/shipwright-ap")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_DR_LIBS" "${dr_libs}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_IMGUI" "${imgui'}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_LIBGFXD" "${libgfxd}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_PRISM" "${prism}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_STORMLIB" "${stormlib'}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_THREADPOOL" "${thread_pool}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_SSLCERTSTORE" "${sslCertStore}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_ASIO" "${asio}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_WEBSOCKETPP" "${websocketpp}/include")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_WSWRAP" "${wswrap}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_APCLIENTPP" "${apclientpp}")
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_VALIJSON" "${valijson}")
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_METALCPP" "${metalcpp}")
    ];

  # libc++ gates floating-point std::from_chars on macOS 26, so valijson's
  # auto-detection picks an unavailable overload. 0 selects its istringstream
  # fallback; only works on valijson >= 1.1.3, which added the macro gate.
  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isDarwin "-Wno-int-conversion -Wno-implicit-int -Wno-elaborated-enum-base -DVALIJSON_HAS_STD_FROM_CHARS=0";

  strictDeps = true;
  __structuredAttrs = true;
  enableParallelBuilding = true;

  dontAddPrefix = true;

  # Linking fails without this
  hardeningDisable = ["format"];

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

    substituteInPlace soh/soh/OTRGlobals.h \
      --replace-fail 'const std::string appShortName = "soh";' 'const std::string appShortName = "soh-ap";'
  '';

  postBuild = ''
    cp ${sdl_gamecontrollerdb}/share/gamecontrollerdb.txt gamecontrollerdb.txt
    cmake --build . --target GenerateSohOtr
  '';

  postInstall =
    ''
      # Vendored dependency headers and static libs; not part of the package.
      rm -r $out/share/shipwright-ap/{include,lib}
    ''
    + lib.optionalString stdenv.hostPlatform.isLinux ''
      mkdir -p $out/bin
      ln -s $out/share/shipwright-ap/soh.elf $out/bin/soh-ap
      install -Dm644 ../soh/macosx/sohIcon.png $out/share/icons/hicolor/512x512/apps/soh-ap.png
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
          "<string>Ship of Harkinian (Archipelago)</string>" \
        --replace-fail \
          "<string>com.shipofharkinian.ShipOfHarkinian</string>" \
          "<string>com.shipofharkinian.ShipOfHarkinian.Archipelago</string>" \
        --replace-fail \
          "<string>~/Library/Application Support/com.shipofharkinian.soh</string>" \
          "<string>~/Library/Application Support/com.shipofharkinian.soh-ap</string>"

      # The install prefix is $out/share/shipwright-ap and upstream installs to
      # DESTINATION ../MacOS and ../Resources, which lands them in $out/share.
      mv $out/share/MacOS $out/Applications/soh-ap.app/Contents/MacOS

      # The install prefix contains all resources that are in "Resources" in
      # the official bundle. We move them to the right place and symlink them
      # back, as that's where the game expects them.
      mv $out/share/Resources $out/Applications/soh-ap.app/Contents/Resources
      mv $out/share/shipwright-ap/** $out/Applications/soh-ap.app/Contents/Resources
      rm -rf $out/share/shipwright-ap
      ln -s $out/Applications/soh-ap.app/Contents/Resources $out/share/shipwright-ap

      # Copy icons
      cp -r ../build/macosx/soh.icns $out/Applications/soh-ap.app/Contents/Resources/soh.icns

      # TODO(Sirius902) This seems like an issue upstream in ship maybe?
      # Move gamecontrollerdb.txt to the proper place for app bundle
      install -Dm644 ${sdl_gamecontrollerdb}/share/gamecontrollerdb.txt \
        $out/Applications/soh-ap.app/Contents/Resources/gamecontrollerdb.txt
    ''
    + ''
      # TODO(Sirius902) Uncomment when upstream adds a root LICENSE file.
      # install -Dm644 -t $out/share/licenses/shipwright-ap ../LICENSE
      test ! -f ../LICENSE || (echo "upstream LICENSE exists now, install it!" && false)

      install -Dm644 -t $out/share/licenses/shipwright-ap/OTRExporter ../OTRExporter/LICENSE
      install -Dm644 -t $out/share/licenses/shipwright-ap/ZAPDTR ../ZAPDTR/LICENSE
      install -Dm644 -t $out/share/licenses/shipwright-ap/libgfxd ${libgfxd}/LICENSE
      install -Dm644 -t $out/share/licenses/shipwright-ap/libultraship ../libultraship/LICENSE
      install -Dm644 -t $out/share/licenses/shipwright-ap/thread_pool ${thread_pool}/LICENSE.txt
    '';

  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    wrapProgram $out/share/shipwright-ap/soh.elf --prefix PATH ":" ${lib.makeBinPath [zenity]}
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "soh-ap";
      icon = "soh-ap";
      exec = "soh-ap";
      comment = finalAttrs.meta.description;
      desktopName = "Ship of Harkinian (Archipelago)";
      categories = ["Game"];
    })
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch=Harkipellago"
      "--version-regex=Client_([0-9]+\\.[0-9]+\\.[0-9]+.*)"
    ];
  };

  meta = {
    homepage = "https://github.com/jeromkiller/Shipwright_archipellago";
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
