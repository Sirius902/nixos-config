final: prev:
prev.cosmic-term.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-23";

  src = prevAttrs.src.override {
    tag = null;
    rev = "2dad2aeb18f2ca84152e39ea257193a0fc2d36b0";
    hash = "sha256-hr6CHnIoqDBbTUsXUfAu7V5SYUqRyjezswVD81GAzjY=";
  };

  cargoHash = "sha256-mpuVSHb9YcDZB+eyyD+5ZNzUeEgx8T25IFjsD/Q/quU=";

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
