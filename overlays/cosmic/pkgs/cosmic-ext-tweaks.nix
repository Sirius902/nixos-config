final: prev:
prev.cosmic-ext-tweaks.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0.1.3-unstable-2025-06-18";

  src = prevAttrs.src.override {
    tag = null;
    rev = "3d212df083d5c3f0cfb9d56929edcc69962e008d";
    hash = "sha256-1ITB1PnTER2dGuH/L/NDuiJmBxTN9hpau2um5tPh1Rg=";
  };

  cargoHash = "sha256-FJg9AuOSNwDHfqO838Vg3OMWr2I6EMGQoUb5YeXOJ0A=";

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
