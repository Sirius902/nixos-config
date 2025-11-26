{pkgs}: rec {
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

  shipwright = pkgs.callPackage ./shipwright/package.nix {SDL2 = SDL2_git;};
  shipwright-ap = pkgs.callPackage ./shipwright/ap/package.nix {SDL2 = SDL2_git;};
  _2ship2harkinian = pkgs.callPackage ./_2ship2harkinian/package.nix {SDL2 = SDL2_git;};

  n64recomp = pkgs.callPackage ./n64recomp/package.nix {};
  z64decompress = pkgs.callPackage ./z64decompress/package.nix {};
  zelda64recomp = pkgs.callPackage ./zelda64recomp/package.nix {
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

  archipelago = pkgs.callPackage ./archipelago/package.nix {};

  wwrando = pkgs.callPackage ./wwrando/package.nix {};
  wwrando-ap = pkgs.callPackage ./wwrando-ap/package.nix {};
}
