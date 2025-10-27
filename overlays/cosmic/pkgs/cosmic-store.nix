final: prev:
prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.3-unstable-2025-10-26";

  src = prevAttrs.src.override {
    tag = null;
    rev = "9027f22989ed023a06464e2d7922514c6a7bad27";
    hash = "sha256-D/P6abNqH++GWBfqZYqGjH3YV+jyyBo/8R3veLm1NRo=";
  };

  cargoHash = "sha256-nJLowAuWvj5JfmPyExQyfCJ9pqNJ0OdzPPku9z7RDWc=";

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
