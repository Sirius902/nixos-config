final: prev:
prev.cosmic-player.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-15";

  src = prevAttrs.src.override {
    tag = null;
    rev = "5556cf81a120fc60aa771e3772424d0e76a91b22";
    hash = "sha256-xDDXdY33ypY7/BIFu2DFv9ik3H4xmIi3QHkeoeFdUBA=";
  };

  cargoHash = "sha256-DodFIfthiGFSvXWfPsPjFhNY6G7z3lb6pfc5HtUXhMo=";

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
