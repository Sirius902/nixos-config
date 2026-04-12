{pkgs}: {
  ghostty-nautilus = pkgs.callPackage ./ghostty-nautilus/package.nix {};

  gcfeederd = pkgs.callPackage ./gcfeederd/package.nix {};
  gcviewer = pkgs.callPackage ./gcviewer/package.nix {};

  gamecube-loader = pkgs.callPackage ./ghidra-extensions/gamecube-loader/package.nix {};
  xex-loader-wv = pkgs.callPackage ./ghidra-extensions/xex-loader-wv/package.nix {};

  kh-melon-mix = pkgs.callPackage ./kh-melon-mix/package.nix {};

  shipwright = pkgs.callPackage ./shipwright/package.nix {};
  shipwright-ap = pkgs.callPackage ./shipwright/ap/package.nix {};
  _2ship2harkinian = pkgs.callPackage ./_2ship2harkinian/package.nix {};

  n64recomp = pkgs.callPackage ./n64recomp/package.nix {};
  z64decompress = pkgs.callPackage ./z64decompress/package.nix {};
  zelda64recomp = pkgs.callPackage ./zelda64recomp/package.nix {};

  wwrando = pkgs.callPackage ./wwrando/package.nix {};
  wwrando-ap = pkgs.callPackage ./wwrando-ap/package.nix {};

  wrye-bash = pkgs.callPackage ./wrye-bash/package.nix {};

  hlsdk-portable = pkgs.callPackage ./hlsdk-portable/package.nix {};
  hlsdk-portable-bshift = pkgs.callPackage ./hlsdk-portable/mods/bshift.nix {};
  hlsdk-portable-opfor = pkgs.callPackage ./hlsdk-portable/mods/opfor.nix {};
  hlsdk-portable-theyhunger = pkgs.callPackage ./hlsdk-portable/mods/theyhunger.nix {};

  xash3d-fwgs = pkgs.callPackage ./xash3d-fwgs/package.nix {};
  xash-dedicated = (pkgs.callPackage ./xash3d-fwgs/package.nix {buildServer = true;}).overrideAttrs (prevAttrs: {
    passthru = removeAttrs (prevAttrs.passthru or {}) ["updateScript"];
  });
}
