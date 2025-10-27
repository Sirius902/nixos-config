final: prev:
prev.cosmic-applets.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.3-unstable-2025-10-24";

  src = prevAttrs.src.override {
    tag = null;
    rev = "1d565fca80de4cc23cc321f8f2d8527cc8761d71";
    hash = "sha256-hBqsFiH2zKwGN9tWEf4iDoVcwssj7YN+7+2ooVNKszs=";
  };

  cargoHash = "sha256-HLbcTDwS5IvolEMb0bZr4CPjtEjZI8G+AggXifIDiKM=";

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
