final: prev:
prev.cosmic-term.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-21";

  src = prevAttrs.src.override {
    tag = null;
    rev = "6fe053bcb16872ab291c106860602e679082a509";
    hash = "sha256-dlm077tKn76cvw/qcbv3XwSMFO4hcrVoNw0e9wqOXt8=";
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
        extraArgs = [
          "--version-regex"
          "epoch-(.*)"
        ];
      };
    };
})
