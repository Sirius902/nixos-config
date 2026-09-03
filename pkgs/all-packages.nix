{pkgs}: let
  packages = {
    anchor-server = pkgs.callPackage ./anchor-server/package.nix {};

    archipelago = pkgs.callPackage ./archipelago/package.nix {
      extraPythonPackages = ps: [
        # Needed by Twilight Princess Client.
        ps.tkinter
      ];
    };
    enemizer-cli = pkgs.callPackage ./enemizer-cli/package.nix {};
    sni = pkgs.callPackage ./sni/package.nix {};

    gcfeederd = pkgs.callPackage ./gcfeederd/package.nix {};
    gcviewer = pkgs.callPackage ./gcviewer/package.nix {};

    gamecube-loader = pkgs.callPackage ./ghidra-extensions/gamecube-loader/package.nix {};
    xex-loader-wv = pkgs.callPackage ./ghidra-extensions/xex-loader-wv/package.nix {};

    kh-melon-mix = pkgs.callPackage ./kh-melon-mix/package.nix {};

    mm-recomp-rando = pkgs.callPackage ./mm-recomp-rando/package.nix {};
    apcpp-glue = pkgs.callPackage ./mm-recomp-rando/glue.nix {};

    sequence-otrizer = pkgs.callPackage ./sequence-otrizer/package.nix {};
    darunias-joy = pkgs.callPackage ./darunias-joy/package.nix {};
    ganondorfs-organ = pkgs.callPackage ./ganondorfs-organ/package.nix {};

    shipwright = pkgs.callPackage ./shipwright/package.nix {};
    shipwright_stable = pkgs.callPackage ./shipwright/stable.nix {};
    shipwright-ap = pkgs.callPackage ./shipwright/ap/package.nix {};
    _2ship2harkinian = pkgs.callPackage ./_2ship2harkinian/package.nix {};

    wwrando = pkgs.callPackage ./wwrando/package.nix {};
    wwrando-ap = pkgs.callPackage ./wwrando-ap/package.nix {};

    dusklight = pkgs.callPackage ./dusklight/package.nix {};
    dusklight-rando = pkgs.callPackage ./dusklight/rando/package.nix {};
    dusklight-ap = pkgs.callPackage ./dusklight/ap/package.nix {};
    dusklight-tphd = pkgs.callPackage ./dusklight/tphd/package.nix {};
    dusklight-randomizer = pkgs.callPackage ./dusklight/mods/randomizer.nix {};
    dusklight-basic-cosmetics = pkgs.callPackage ./dusklight/mods/basic-cosmetics.nix {};

    wrye-bash = pkgs.callPackage ./wrye-bash/package.nix {};

    hlsdk-portable = pkgs.callPackage ./hlsdk-portable/package.nix {};
    hlsdk-portable-bshift = pkgs.callPackage ./hlsdk-portable/mods/bshift.nix {};
    hlsdk-portable-opfor = pkgs.callPackage ./hlsdk-portable/mods/opfor.nix {};
    hlsdk-portable-theyhunger = pkgs.callPackage ./hlsdk-portable/mods/theyhunger.nix {};

    xash3d-fwgs = pkgs.callPackage ./xash3d-fwgs/package.nix {};
    xash-dedicated = (pkgs.callPackage ./xash3d-fwgs/package.nix {buildServer = true;}).overrideAttrs (prevAttrs: {
      passthru = removeAttrs (prevAttrs.passthru or {}) ["updateScript"];
    });
  };
in
  # Give every package the docs/package-layout.md check. Wiring it here instead
  # of per-package covers new entries by construction.
  builtins.mapAttrs (_: package:
    package.overrideAttrs (finalAttrs: prevAttrs: {
      passthru =
        (prevAttrs.passthru or {})
        // {
          tests =
            (prevAttrs.passthru.tests or {})
            // {layout = pkgs.checkOutputLayout finalAttrs.finalPackage;};
        };
    }))
  packages
