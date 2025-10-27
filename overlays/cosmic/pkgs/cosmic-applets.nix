final: prev:
prev.cosmic-applets.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1.1-unstable-2025-09-19";

  src = prevAttrs.src.override {
    tag = null;
    rev = "2dba07fcae15ff93ea08afac111655325c1a3eca";
    hash = "sha256-uUcEwa9rGHLzmlutmLl/e38ZqybfYMU0Dhe+FsT5V/E=";
  };

  cargoHash = "sha256-RnkyIlTJMxMGu+EsmZwvSIapSqdng+t8bqMVsDXprlU=";

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
