# Yoinked from https://github.com/NixOS/nixpkgs/pull/313013.
# https://github.com/NixOS/nixpkgs/blob/8dccd27f0feef3b0c1bb21a0b86e428a45a8be3c/pkgs/by-name/ze/zelda64recomp/package.nix
{
  lib,
  mm64baserom ? null,
  requireFile,
  fetchFromGitHub,
  llvmPackages_19,
  cmake,
  copyDesktopItems,
  installShellFiles,
  makeWrapper,
  ninja,
  pkg-config,
  wrapGAppsHook3,
  SDL2,
  gtk3,
  vulkan-loader,
  makeDesktopItem,
  z64decompress,
  n64recomp,
  directx-shader-compiler,
  forceX11 ? false,
  nix-update-script,
}: let
  baseRom =
    if mm64baserom != null
    then mm64baserom
    else
      requireFile {
        name = "mm.us.rev1.rom.z64";
        message = ''
          zelda64recomp currently only supports the US version of Majora's Mask.
          Please dump your copy and rename it to mm.us.rev1.rom.z64
          and add it to the nix store using
          nix-store --add-fixed sha256 mm.us.rev1.rom.z64
          See https://dumping.guide/carts/nintendo/n64 for more details.
        '';
        hash = "sha256-77E2WzrjYmBFFMD5oaLRH13IaIulvmYKN96/XjvkPys=";
      };
in
  llvmPackages_19.stdenv.mkDerivation (finalAttrs: {
    pname = "zelda64recomp";
    version = "1.2.0-unstable-2025-08-16";

    src = fetchFromGitHub {
      owner = "Zelda64Recomp";
      repo = "Zelda64Recomp";
      rev = "b5360b054680a6d7fcb9e4b59ef41870ff494901";
      hash = "sha256-63479zVEH3A+hbZmx17qZ8SSlGqTYituW6S86e7wBHA=";
      fetchSubmodules = true;
    };

    strictDeps = true;

    nativeBuildInputs = [
      cmake
      copyDesktopItems
      installShellFiles
      llvmPackages_19.lld
      makeWrapper
      ninja
      pkg-config
      wrapGAppsHook3
    ];

    buildInputs = [
      SDL2
      gtk3
      vulkan-loader
    ];

    desktopItems = [
      (makeDesktopItem {
        name = "Zelda64Recompiled";
        icon = "zelda64recomp";
        exec = "Zelda64Recompiled";
        comment = "Static recompilation of Majora's Mask";
        genericName = "Static recompilation of Majora's Mask";
        desktopName = "Zelda 64: Recompiled";
        categories = ["Game"];
      })
    ];

    preConfigure = ''
      ln -s ${baseRom} ./mm.us.rev1.rom.z64
      ${lib.getExe z64decompress} mm.us.rev1.rom.z64 mm.us.rev1.rom_uncompressed.z64
      cp ${n64recomp}/bin/* .

      ./N64Recomp us.rev1.toml
      ./RSPRecomp aspMain.us.rev1.toml
      ./RSPRecomp njpgdspMain.us.rev1.toml

      substituteInPlace lib/rt64/CMakeLists.txt \
        --replace-fail "\''${PROJECT_SOURCE_DIR}/src/contrib/dxc/lib/x64" "${directx-shader-compiler}/lib/" \
        --replace-fail "\''${PROJECT_SOURCE_DIR}/src/contrib/dxc/bin/x64/dxc-linux" "${directx-shader-compiler}/bin/dxc" \
        --replace-fail "\''${PROJECT_SOURCE_DIR}/src/contrib/dxc/inc" "${directx-shader-compiler.src}/include/dxc"

      substituteInPlace CMakeLists.txt \
        --replace-fail "\''${PROJECT_SOURCE_DIR}/lib/rt64/src/contrib/dxc/lib/x64" "${directx-shader-compiler}/lib/" \
        --replace-fail "\''${PROJECT_SOURCE_DIR}/lib/rt64/src/contrib/dxc/bin/x64/dxc-linux" "${directx-shader-compiler}/bin/dxc"
    '';

    # This is required or else nothing will build
    hardeningDisable = [
      "format"
      "pic"
      "stackprotector"
      "zerocallusedregs"
    ];

    installPhase = ''
      runHook preInstall

      installBin Zelda64Recompiled
      install -Dm644 -t $out/share ../recompcontrollerdb.txt
      install -Dm644 ../icons/512.png $out/share/icons/hicolor/scalable/apps/zelda64recomp.png
      cp -r ../assets $out/share/
      ln -s $out/share/recompcontrollerdb.txt $out/bin/recompcontrollerdb.txt
      ln -s $out/share/assets $out/bin/assets

      install -Dm644 -t $out/share/licenses/zelda64recomp ../COPYING
      install -Dm644 -t $out/share/licenses/zelda64recomp/N64ModernRuntime ../lib/N64ModernRuntime/COPYING
      install -Dm644 -t $out/share/licenses/zelda64recomp/RmlUi ../lib/RmlUi/LICENSE.txt
      install -Dm644 -t $out/share/licenses/zelda64recomp/lunasvg ../lib/lunasvg/LICENSE
      install -Dm644 -t $out/share/licenses/zelda64recomp/rt64 ../lib/rt64/LICENSE

      runHook postInstall
    '';

    preFixup = ''
      gappsWrapperArgs+=(
         --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [vulkan-loader]}
       )
    '';

    # This is needed as Zelda64Recompiled will segfault when not run from the same
    # directory as the binary. It also used to exit when run without X11. Recent rt64
    # updates enabled wayland support, but leave the option to disable this on the
    # application level if desired.
    postFixup = ''
      wrapProgram $out/bin/Zelda64Recompiled --chdir "$out/bin/" \
          ${lib.optionalString forceX11 ''--set SDL_VIDEODRIVER x11''}
    '';

    passthru.updateScript = nix-update-script {
      extraArgs = [
        "--version-regex"
        "v(.*)"
      ];
    };

    meta = {
      description = "Static recompilation of Majora's Mask (and soon Ocarina of Time) for PC (Windows/Linux)";
      homepage = "https://github.com/Zelda64Recomp/Zelda64Recomp";
      license = with lib.licenses; [
        # Zelda64Recomp, N64ModernRuntime
        gpl3Only

        # RT64, RmlUi, lunasvg, sse2neon
        mit

        # reverse engineering
        unfree
      ];
      maintainers = with lib.maintainers; [qubitnano];
      mainProgram = "Zelda64Recompiled";
      platforms = ["x86_64-linux"];
    };
  })
