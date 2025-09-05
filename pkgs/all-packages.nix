{
  pkgs,
  nixpkgs-ghidra_11_2_1,
}: rec {
  ghostty-nautilus = pkgs.callPackage ./ghostty-nautilus/package.nix {};

  gcfeeder = pkgs.callPackage ./gcfeeder/package.nix {};
  gcfeederd = pkgs.callPackage ./gcfeederd/package.nix {};
  gcviewer = pkgs.callPackage ./gcviewer/package.nix {};

  gamecube-loader = nixpkgs-ghidra_11_2_1.legacyPackages.${pkgs.system}.callPackage ./ghidra-extensions/gamecube-loader/package.nix {};

  observatory = pkgs.callPackage ./observatory/package.nix {};

  sdl3_git = pkgs.callPackage ./sdl3_git/package.nix {};
  SDL2_git = pkgs.callPackage ./SDL2_git/package.nix {};

  sdl_gamecontrollerdb = pkgs.callPackage ./sdl_gamecontrollerdb/package.nix {};

  sdl3-ship = sdl3_git.overrideAttrs (prevAttrs: {
    patches =
      (prevAttrs.patches or [])
      ++ [
        ../patches/sdl3/0001-Use-digital-input-for-NSO-GameCube-triggers.patch
      ];
  });
  SDL2-ship = SDL2_git.override {sdl3_git = sdl3-ship;};

  shipwright = pkgs.callPackage ./shipwright/package.nix {SDL2 = SDL2-ship;};
  shipwright-anchor = pkgs.callPackage ./shipwright/anchor/package.nix {SDL2 = SDL2-ship;};
  shipwright-ap = pkgs.callPackage ./shipwright/ap/package.nix {SDL2 = SDL2-ship;};
  _2ship2harkinian = pkgs.callPackage ./_2ship2harkinian/package.nix {SDL2 = SDL2-ship;};

  n64recomp = pkgs.callPackage ./n64recomp/package.nix {};
  z64decompress = pkgs.callPackage ./z64decompress/package.nix {};
  zelda64recomp = pkgs.callPackage ./zelda64recomp/package.nix {SDL2 = SDL2-ship;};

  archipelago = pkgs.callPackage ./archipelago/package.nix {};
}
