final: prev:
prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.7-unstable-2025-11-24";

  src = prevAttrs.src.override {
    tag = null;
    rev = "853503af7b42cca833a6a1dbf18b7c1aab2a7a62";
    hash = "sha256-rrM0ibnapXv+IYDPqw/dXQJ44cDWPNlz7rREVQw5J1o=";
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
