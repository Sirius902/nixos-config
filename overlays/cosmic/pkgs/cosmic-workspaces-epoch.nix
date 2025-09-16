final: prev:
prev.cosmic-workspaces-epoch.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-16";

  src = prevAttrs.src.override {
    tag = null;
    rev = "3aad95d4638e4db30c00d922fbc3a1e48d294c30";
    hash = "sha256-d700tkElUX9Oa26xyHggeQsaw3f7m4v5cEEDIAOAZuQ=";
  };

  cargoHash = "sha256-tfC6cJMiun7O5tBrxpffCicaKRMGbCPi2oWISMvB8ZM=";

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
