final: prev:
prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-15";

  src = prevAttrs.src.override {
    tag = null;
    rev = "2c9d4374823f6ff466a895e6700b45d266c099f2";
    hash = "sha256-EPt8pjLlQLv9xzcKtv8fDSqhZcmuC+AvIhosMMpCs88=";
  };

  cargoHash = "sha256-X6XTanAFQFTxs1w7As3QpRcSRCbSTEJmo7HTG6bk4v4=";

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
