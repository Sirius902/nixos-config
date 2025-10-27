final: prev:
prev.cosmic-files.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1.1-unstable-2025-09-26";

  src = prevAttrs.src.override {
    tag = null;
    rev = "225eaa0b35ff7ba1c6e18669136eeb8ad5f174b4";
    hash = "sha256-XHSMHi5DU1kGIGOrKVy6kRSlwMnboY68oUh17JjB19s=";
  };

  cargoHash = "sha256-7RANj+aXdmBVO66QDgcNrrU4qEGK4Py4+ZctYWU1OO8=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
    patches =
      if builtins.hasAttr "cargoPatches" finalAttrs
      then finalAttrs.cargoPatches
      else null;
  };

  passthru.updateScript = final.nix-update-script {
    extraArgs = ["--version-regex=epoch-(.*)"];
  };
})
