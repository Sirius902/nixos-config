{
  pkgs,
  nixpkgs-ghidra_11_2_1,
}: {
  ghostty-nautilus = pkgs.callPackage ./ghostty-nautilus/package.nix {};

  gcfeeder = pkgs.callPackage ./gcfeeder/package.nix {};

  gcfeederd = pkgs.callPackage ./gcfeederd/package.nix {};

  gcviewer = pkgs.callPackage ./gcviewer/package.nix {};

  gamecube-loader = nixpkgs-ghidra_11_2_1.legacyPackages.${pkgs.system}.callPackage ./ghidra-extensions/gamecube-loader/package.nix {};

  shipwright = pkgs.callPackage ./shipwright/package.nix {};

  _2ship2harkinian = pkgs.callPackage ./_2ship2harkinian/package.nix {};

  shipwright-anchor = pkgs.callPackage ./shipwright/anchor/package.nix {};
  shipwright-ap = pkgs.callPackage ./shipwright/ap/package.nix {};

  observatory = pkgs.callPackage ./observatory/package.nix {};

  n64recomp = pkgs.callPackage ./n64recomp/package.nix {};
  z64decompress = pkgs.callPackage ./z64decompress/package.nix {};
  zelda64recomp = pkgs.callPackage ./zelda64recomp/package.nix {};
}
