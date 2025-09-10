final: prev:
prev.cosmic-applibrary.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-08";

  src = prevAttrs.src.override {
    tag = null;
    rev = "893fe70c5d575231c62c4bbccc4aed97bceba77e";
    hash = "sha256-FKUkpGr8mEFYpi+EOIltfPLM9QV6/AqxMT1Qtp6KAK0=";
  };

  cargoHash = "sha256-RSbGqziausEeG5LyWFiGjLdRsOsetQ7SVQHwD/d3mmU=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
    patches =
      if builtins.hasAttr "cargoPatches" finalAttrs
      then finalAttrs.cargoPatches
      else null;
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = final.nix-update-script {
        extraArgs = [
          "--version-regex"
          "epoch-(.*)"
        ];
      };
    };
})
