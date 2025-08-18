final: prev:
prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-18";

  src = prevAttrs.src.override {
    tag = null;
    rev = "88deb72f5357a77c926f96564fcfd9d6d1b55b1b";
    hash = "sha256-7APOKC7V6d1k1245FwMtj5EfeIO24Lb/CqkH4MzIRDo=";
  };

  cargoHash = "sha256-/k/aMiR/OrsdgkN8hJWVYfZMvnZKyTzEEn9qO11S6J0=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
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
