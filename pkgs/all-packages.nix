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

  shipwright = pkgs.callPackage ./shipwright/package.nix {SDL2 = SDL2_git;};

  _2ship2harkinian = pkgs.callPackage ./_2ship2harkinian/package.nix {SDL2 = SDL2_git;};

  shipwright-anchor = pkgs.callPackage ./shipwright/anchor/package.nix {SDL2 = SDL2_git;};
  shipwright-ap = pkgs.callPackage ./shipwright/ap/package.nix {SDL2 = SDL2_git;};

  n64recomp = pkgs.callPackage ./n64recomp/package.nix {};
  z64decompress = pkgs.callPackage ./z64decompress/package.nix {};
  zelda64recomp = pkgs.callPackage ./zelda64recomp/package.nix {SDL2 = SDL2_git;};
}
