final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1.1-unstable-2025-09-25";

  src = prevAttrs.src.override {
    tag = null;
    rev = "85543122d33852c48825dcc8d61d5f2048bdfec6";
    hash = "sha256-vIc6A3jOltf2/Di/lBcEE70MAqXbN2c26x8ZlZYq59U=";
  };

  cargoHash = "sha256-dHyUTV5txSLWEDE7Blplz8CBvyuUmYNNr1kbifujHKk=";

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
        extraArgs = ["--version-regex=epoch-(.*)"];
      };
    };
})
