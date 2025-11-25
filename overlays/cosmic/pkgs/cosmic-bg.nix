final: prev:
prev.cosmic-bg.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.7-unstable-2025-11-04";

  src = prevAttrs.src.override {
    tag = null;
    rev = "21a16f4ac19cd1c37cf9d7464888b9f4f90cc9fa";
    hash = "sha256-RPVPiMEwMh4DRixaC8A4oK9KzGIbi2CFlVAthICalt0=";
  };

  cargoHash = "sha256-+NkraWjWHIMIyktAUlp3q2Ot1ib1QRsBBvfdbr5BXto=";

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
