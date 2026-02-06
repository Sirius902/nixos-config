{pkgs}: {
  ghostty-nautilus = pkgs.callPackage ./ghostty-nautilus/package.nix {};

  gcfeeder = pkgs.callPackage ./gcfeeder/package.nix {};
  gcfeederd = pkgs.callPackage ./gcfeederd/package.nix {};
  gcviewer = pkgs.callPackage ./gcviewer/package.nix {};

  gamecube-loader = pkgs.callPackage ./ghidra-extensions/gamecube-loader/package.nix {};
  xex-loader-wv = pkgs.callPackage ./ghidra-extensions/xex-loader-wv/package.nix {};

  kh-melon-mix = pkgs.callPackage ./kh-melon-mix/package.nix {};

  sdl_gamecontrollerdb = pkgs.callPackage ./sdl_gamecontrollerdb/package.nix {};

  shipwright = pkgs.callPackage ./shipwright/package.nix {};
  shipwright-ap = pkgs.callPackage ./shipwright/ap/package.nix {};
  _2ship2harkinian = pkgs.callPackage ./_2ship2harkinian/package.nix {};

  n64recomp = pkgs.callPackage ./n64recomp/package.nix {};
  z64decompress = pkgs.callPackage ./z64decompress/package.nix {};
  zelda64recomp = pkgs.callPackage ./zelda64recomp/package.nix {};

  archipelago = pkgs.callPackage ./archipelago/package.nix {};

  wwrando = pkgs.callPackage ./wwrando/package.nix {};
  wwrando-ap = pkgs.callPackage ./wwrando-ap/package.nix {};

  wrye-bash = pkgs.callPackage ./wrye-bash/package.nix {};

  # FUTURE(Sirius902) I hope this PR lives :(
  # https://github.com/NixOS/nixpkgs/pull/384728
  xash-sdk = pkgs.callPackage ./xash-sdk/package.nix {};
  xash-sdk-bshift = pkgs.callPackage ./xash-sdk/mods/bshift.nix {};
  xash-sdk-opfor = pkgs.callPackage ./xash-sdk/mods/opfor.nix {};
  xash-sdk-theyhunger = pkgs.callPackage ./xash-sdk/mods/theyhunger.nix {};

  xash3d-fwgs = pkgs.callPackage ./xash3d-fwgs/package.nix {};
  xash-dedicated = pkgs.callPackage ./xash-dedicated/package.nix {};
}
