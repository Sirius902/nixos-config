final: prev:
prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-15";

  src = prevAttrs.src.override {
    tag = null;
    rev = "c574a430bd1d56a506a7deb26ffa956f61a9a305";
    hash = "sha256-NRBg+sdPW9x+L7Nery0KGuj9VGML9iq52PpJh4SzSDY=";
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
