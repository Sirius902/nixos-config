{pkgs}: let
  makeNsoGcTriggersDigital = linuxBin: pkg:
    (pkg.override (pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      # On Darwin the hidapi driver isn't usable without entitlements so just treat it as a regular controller and init hid via a separate program.
      sdl_gamecontrollerdb = pkgs.sdl_gamecontrollerdb.overrideAttrs (prevAttrs: {
        postInstall =
          (prevAttrs.postInstall or "")
          + ''
            echo "030046457e0500007320000001010000,Nintendo GameCube Controller,crc:4546,platform:macOS,a:b1,b:b3,dpdown:b8,dpleft:b10,dpright:b9,dpup:b11,guide:b16,leftshoulder:b13,lefttrigger:b12,leftx:a0,lefty:a1~,misc1:b17,misc2:b20,rightshoulder:b5,righttrigger:b4,rightx:a2,righty:a3~,start:b6,x:b0,y:b2,hint:!SDL_GAMECONTROLLER_USE_GAMECUBE_LABELS:=1," >> $out/share/gamecontrollerdb.txt
          '';
      });
    })).overrideAttrs (prevAttrs: {
      # On Linux, set `SDL_GAMECONTROLLERCONFIG` to override the hidapi binding (setting it in sdl_gamecontrollerdb is not sufficient).
      postFixup =
        (prevAttrs.postFixup or "")
        + pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
          wrapProgram ${linuxBin} \
            --suffix SDL_GAMECONTROLLERCONFIG $'\n' \
              "030046457e0500007320000001016800,Nintendo GameCube Controller,a:b0,b:b1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,guide:b4,leftshoulder:b6,lefttrigger:b10,leftx:a0,lefty:a1,rightshoulder:b7,righttrigger:b11,rightx:a2,righty:a3,start:b5,x:b2,y:b3,misc1:b8,misc2:b9,hint:!SDL_GAMECONTROLLER_USE_GAMECUBE_LABELS:=1,"
        '';
    });
in rec {
  ghostty-nautilus = pkgs.callPackage ./ghostty-nautilus/package.nix {};

  gcfeeder = pkgs.callPackage ./gcfeeder/package.nix {};
  gcfeederd = pkgs.callPackage ./gcfeederd/package.nix {};
  gcviewer = pkgs.callPackage ./gcviewer/package.nix {};

  gamecube-loader = pkgs.callPackage ./ghidra-extensions/gamecube-loader/package.nix {};

  kh-melon-mix = pkgs.callPackage ./kh-melon-mix/package.nix {};

  observatory = pkgs.callPackage ./observatory/package.nix {};

  sdl3_git = pkgs.callPackage ./sdl3_git/package.nix {};
  SDL2_git = pkgs.callPackage ./SDL2_git/package.nix {};

  sdl_gamecontrollerdb = pkgs.callPackage ./sdl_gamecontrollerdb/package.nix {};

  shipwright = makeNsoGcTriggersDigital "$out/lib/soh.elf" (pkgs.callPackage ./shipwright/package.nix {SDL2 = SDL2_git;});
  shipwright-ap = makeNsoGcTriggersDigital "$out/lib/soh.elf" (pkgs.callPackage ./shipwright/ap/package.nix {SDL2 = SDL2_git;});
  _2ship2harkinian = makeNsoGcTriggersDigital "$out/lib/2s2h.elf" (pkgs.callPackage ./_2ship2harkinian/package.nix {SDL2 = SDL2_git;});

  n64recomp = pkgs.callPackage ./n64recomp/package.nix {};
  z64decompress = pkgs.callPackage ./z64decompress/package.nix {};
  zelda64recomp = let
    pkg = pkgs.callPackage ./zelda64recomp/package.nix {
      SDL2 = SDL2_git;
      # FUTURE(Sirius902) The game crashes after loading a file on the following commit, pin to the previous commit.
      # https://github.com/N64Recomp/N64Recomp/commit/afc2ff93a5b71b3f5aac34940bb84a87d2ea7e0b
      n64recomp = n64recomp.overrideAttrs (prevAttrs: {
        version = "0-unstable-2025-09-06";
        src = prevAttrs.src.override {
          rev = "a49c51b37f841c9d5bec20f1eab345167f27f566";
          hash = "sha256-kAlmCNVDTUjfA5vPb/bTMZGgXzIucD9X8/FdAGuHjJc=";
        };
      });
    };
  in
    # Avoid overriding nonexistent sdl_gamecontrollerdb arg on darwin.
    # FUTURE(Sirius902) This is kinda ugly though.
    if pkgs.stdenv.hostPlatform.isDarwin
    then pkg
    else makeNsoGcTriggersDigital "$out/bin/Zelda64Recompiled" pkg;

  archipelago = pkgs.callPackage ./archipelago/package.nix {};

  wwrando = pkgs.callPackage ./wwrando/package.nix {};
  wwrando-ap = pkgs.callPackage ./wwrando-ap/package.nix {};
}
