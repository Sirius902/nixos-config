final: prev:
prev.cosmic-files.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1.1-unstable-2025-09-24";

  src = prevAttrs.src.override {
    tag = null;
    rev = "0c222e1e3a9da73c32240858c3dafc81956396f0";
    hash = "sha256-pSjmsWsGGhjCekMTX8iiNVbF5X33zg5YVDWtemjIDWU=";
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
