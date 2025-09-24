final: prev:
prev.cosmic-ext-calculator.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0.2.0-unstable-2025-09-24";

  src = prevAttrs.src.override {
    tag = null;
    rev = "36e3c2ec2486bb667487eb800a4429aaedb6ebb6";
    hash = "sha256-Bl0luQ2/vMm5WWNKX4MFDfkSTM/npgcZtWqA3LsdDWc=";
  };

  cargoHash = "sha256-6zwh7xGx/hnXuS9+upp2zxTmRKj9J3Rn8EC3SEwwnmQ=";

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
      updateScript = final.nix-update-script {};
    };
})
