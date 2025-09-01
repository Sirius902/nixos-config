final: prev:
prev.cosmic-ext-tweaks.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0.1.3-unstable-2025-08-31";

  src = prevAttrs.src.override {
    tag = null;
    rev = "7db3522a2900c738e98b6dc3444be3c340a80564";
    hash = "sha256-imwmO6EmLZYjJO0S+YxNGM4aA4nkyJ1I93ruXEu2+ic=";
  };

  cargoHash = "sha256-X1ER0iYp0s2ap3FQfvXrXTyFOo1QdW+ftNaNvtYdjRs=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };

  passthru =
    (prevAttrs.passthru or {})
    // {
      updateScript = final.nix-update-script {};
    };
})
