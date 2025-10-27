final: prev:
prev.cosmic-workspaces-epoch.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.3-unstable-2025-10-12";

  src = prevAttrs.src.override {
    tag = null;
    rev = "b7afe231d0922ea707f805677b9578f1e4d5e001";
    hash = "sha256-WHMOA7fNPIAwaQmzqyo+XlBYl+13cz0LrRpT0GUa8Vs=";
  };

  cargoHash = "sha256-BE6s2dmbgXlFXrtd8b9k2LltLnegLzWbIUlaEQvv+5o=";

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
