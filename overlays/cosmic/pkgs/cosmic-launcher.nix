final: prev:
prev.cosmic-launcher.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.7-unstable-2025-11-18";

  src = prevAttrs.src.override {
    tag = null;
    rev = "aea652afa85abdc9e62c0b8a33b31c906abccae6";
    hash = "sha256-lVNvmpiShkdT+VZMxV1bvYyC17edaepwlkmOvNMng8k=";
  };

  cargoHash = "sha256-pHW7kBbEQ8P9Ugkgzn1olSlMCeetuNQ2jMJyEteoeIo=";

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
