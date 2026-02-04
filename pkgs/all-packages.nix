{pkgs}: rec {
  ghostty-nautilus = pkgs.callPackage ./ghostty-nautilus/package.nix {};

  gcfeeder = pkgs.callPackage ./gcfeeder/package.nix {};
  gcfeederd = pkgs.callPackage ./gcfeederd/package.nix {};
  gcviewer = pkgs.callPackage ./gcviewer/package.nix {};

  gamecube-loader = pkgs.callPackage ./ghidra-extensions/gamecube-loader/package.nix {};
  xex-loader-wv = pkgs.callPackage ./ghidra-extensions/xex-loader-wv/package.nix {};

  kh-melon-mix = pkgs.callPackage ./kh-melon-mix/package.nix {};

  sdl3_git = pkgs.callPackage ./sdl3_git/package.nix {};
  SDL2_git = pkgs.callPackage ./SDL2_git/package.nix {};

  sdl_gamecontrollerdb = pkgs.callPackage ./sdl_gamecontrollerdb/package.nix {};

  shipwright = pkgs.callPackage ./shipwright/package.nix {SDL2 = SDL2_git;};
  shipwright-ap = pkgs.callPackage ./shipwright/ap/package.nix {SDL2 = SDL2_git;};
  _2ship2harkinian = pkgs.callPackage ./_2ship2harkinian/package.nix {SDL2 = SDL2_git;};

  n64recomp = pkgs.callPackage ./n64recomp/package.nix {};
  z64decompress = pkgs.callPackage ./z64decompress/package.nix {};
  zelda64recomp = pkgs.callPackage ./zelda64recomp/package.nix {SDL2 = SDL2_git;};

  archipelago = pkgs.callPackage ./archipelago/package.nix {};

  wwrando = pkgs.callPackage ./wwrando/package.nix {};
  wwrando-ap = pkgs.callPackage ./wwrando-ap/package.nix {};

  wrye-bash = pkgs.callPackage ./wrye-bash/package.nix {};

  # FUTURE(Sirius902) I hope this PR lives :(
  # https://github.com/NixOS/nixpkgs/pull/384728
  xash-sdk = pkgs.callPackage ./xash-sdk/package.nix {};
}
