final: prev:
prev.cosmic-files.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-23";

  src = prevAttrs.src.override {
    tag = null;
    rev = "3f0a321da4261745257d91a7cdd43a4cd1273338";
    hash = "sha256-HpcKi07OCUlDab5wrMa3khpZREaJSBZh8DYOht/hLKY=";
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
