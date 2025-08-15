{
  pkgs,
  nixpkgs-ghidra_11_2_1,
}: rec {
  ghostty-nautilus = pkgs.callPackage ./ghostty-nautilus/package.nix {};

  gcfeeder = pkgs.callPackage ./gcfeeder/package.nix {};

  gcfeederd = pkgs.callPackage ./gcfeederd/package.nix {};

  gcviewer = pkgs.callPackage ./gcviewer/package.nix {};

  gamecube-loader = nixpkgs-ghidra_11_2_1.legacyPackages.${pkgs.system}.callPackage ./ghidra-extensions/gamecube-loader/package.nix {};

  shipwright = pkgs.callPackage ./shipwright/package.nix {};

  _2ship2harkinian = pkgs.callPackage ./_2ship2harkinian/package.nix {};

  shipwright-anchor = pkgs.callPackage ./shipwright/anchor/package.nix {};

  observatory = pkgs.callPackage ./observatory/package.nix {};

  n64recomp = pkgs.callPackage ./n64recomp/package.nix {};
  z64decompress = pkgs.callPackage ./z64decompress/package.nix {};
  zelda64recomp = pkgs.callPackage ./zelda64recomp/package.nix {
    # FUTURE(Sirius902) zelda64recomp won't compile on the latest dev commit of n64recomp currently.
    n64recomp = n64recomp.overrideAttrs (prevAttrs: {
      version = "unstable-2025-08-11";

      src = prevAttrs.src.override {
        rev = "facc80704901430fcd90513e607be87796254e73";
        hash = "sha256-FUHvQzZOdBzoIb9pgakbKkOOLKXfdVZsGWgoxOtRJ1E=";
      };
    });
  };
}
