final: prev:
prev.cosmic-files.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-22";

  src = prevAttrs.src.override {
    tag = null;
    rev = "ea5b838bc52d0f7d6299051658dc1a9e91070f68";
    hash = "sha256-hMRjox+gKHUuTPRu2oFMyD7K45P7SXYefkfqqhk1OBc=";
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
