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
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "shipwright-anchor";
  version = "533109d";

  src = fetchFromGitHub {
    owner = "garrettjoecox";
    repo = "OOT";
    rev = finalAttrs.version;
    hash = "sha256-xzaTuBeGtTfux59pWk/U7LQimv9WiXC4L8NeQNUvVZc=";
    fetchSubmodules = true;
  };

  patches = [
    (fetchpatch {
      name = "darwin-fixes.patch";
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/e36aedc39401266c6aa5b2a9774290938a823c7d/pkgs/by-name/sh/shipwright/darwin-fixes.patch";
      hash = "sha256-mf/XMkelAkDJ+rGYu9OPzXLC1OaHwAjZRoLe1As7GoA=";
    })
    (fetchpatch {
      name = "gcc14.patch";
      url = "https://github.com/HarbourMasters/Shipwright/commit/1bc15d5bf3042d4fd64e1952eb68c47a7d5d8061.patch";
      hash = "sha256-OpjP+rGqx56DB4W8yzLkxuxSAQa6oXQqtbQ2cNcFjYQ=";
    })
    (fetchpatch {
      name = "any-cursor-equip-swap-fix.patch";
      url = "https://github.com/HarbourMasters/Shipwright/commit/bfe13906e9c1e21e06f7afa1313b0ee4de825d32.patch";
      hash = "sha256-1rtQLoKSufVhRvDrQwV2GoYUqtd1fPFsSQ7xX45F9/c=";
    })
    ./boost_custom.patch
    ./app-name.patch
  ];

  # This would get fetched at build time otherwise, see:
  # https://github.com/HarbourMasters/Shipwright/blob/e46c60a7a1396374e23f7a1f7122ddf9efcadff7/soh/CMakeLists.txt#L736
  gamecontrollerdb = fetchurl {
    name = "gamecontrollerdb.txt";
    url = "https://raw.githubusercontent.com/gabomdq/SDL_GameControllerDB/075c1549075ef89a397fd7e0663d21e53a2485fd/gamecontrollerdb.txt";
    hash = "sha256-atjc0t921l6JSUAd/Yk7uup2R7mCp5ivAh6Dr7HBY7I=";
  };

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
      boost
      glew
      SDL2
      SDL2_net
      libpng
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
    (lib.cmakeFeature "CMAKE_INSTALL_PREFIX" "${placeholder "out"}/lib")
    (lib.cmakeBool "BUILD_REMOTE_CONTROL" true)
  ];

  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isDarwin "-Wno-int-conversion -Wno-implicit-int";

  dontAddPrefix = true;

  # Linking fails without this
  hardeningDisable = ["format"];

  postBuild = ''
    cp ${finalAttrs.gamecontrollerdb} ${finalAttrs.gamecontrollerdb.name}
    ${cmake}/bin/cmake --build "$PWD" --target GenerateSohOtr
  '';

  preInstall =
    lib.optionalString stdenv.hostPlatform.isLinux ''
      # Cmake likes it here for its install paths
      cp ../OTRExporter/soh.otr ..
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      cp ../OTRExporter/soh.otr soh/soh.otr
    '';

  postInstall =
    lib.optionalString stdenv.hostPlatform.isLinux ''
      mkdir -p $out/bin
      ln -s $out/lib/soh.elf $out/bin/soh-anchor
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

      # "lib" contains all resources that are in "Resources" in the official bundle.
      # We move them to the right place and symlink them back to $out/lib,
      # as that's where the game expects them.
      mv $out/Resources $out/Applications/soh.app/Contents/Resources
      mv $out/lib/** $out/Applications/soh.app/Contents/Resources
      rm -rf $out/lib
      ln -s $out/Applications/soh.app/Contents/Resources $out/lib

      # Copy icons
      cp -r ../build/macosx/soh.icns $out/Applications/soh.app/Contents/Resources/soh.icns

      # Fix executable
      install_name_tool -change @executable_path/../Frameworks/libSDL2-2.0.0.dylib \
                        ${SDL2}/lib/libSDL2-2.0.0.dylib \
                        $out/Applications/soh.app/Contents/Resources/soh-macos
      install_name_tool -change @executable_path/../Frameworks/libGLEW.2.2.0.dylib \
                        ${glew}/lib/libGLEW.2.2.0.dylib \
                        $out/Applications/soh.app/Contents/Resources/soh-macos
      install_name_tool -change @executable_path/../Frameworks/libpng16.16.dylib \
                        ${libpng}/lib/libpng16.16.dylib \
                        $out/Applications/soh.app/Contents/Resources/soh-macos

      # Codesign (ad-hoc)
      codesign -f -s - $out/Applications/soh.app/Contents/Resources/soh-macos
    '';

  fixupPhase = lib.optionalString stdenv.hostPlatform.isLinux ''
    wrapProgram $out/lib/soh.elf --prefix PATH ":" ${lib.makeBinPath [zenity]}
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "soh-anchor";
      icon = "soh";
      exec = "soh-anchor";
      comment = finalAttrs.meta.description;
      genericName = "Ship of Harkinian";
      desktopName = "soh-anchor";
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
