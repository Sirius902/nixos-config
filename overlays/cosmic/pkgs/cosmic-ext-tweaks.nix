final: prev:
prev.cosmic-ext-tweaks.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0.1.3-unstable-2025-09-02";

  src = prevAttrs.src.override {
    tag = null;
    rev = "04dd3074269dde62a64d83a3df504513bc847108";
    hash = "sha256-BqiVu1ffF7aMxBLX5G23OonPa3sHYwtYSczUt3v5JjM=";
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
