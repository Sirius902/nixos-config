final: prev:
prev.cosmic-ext-tweaks.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0.1.3-unstable-2025-09-13";

  src = prevAttrs.src.override {
    tag = null;
    rev = "ec683d517fe240aea47175b7e071244f181d3407";
    hash = "sha256-q0kK2KbSpd1aZapfrEkaRfwqgZ0NmOwghYzG3kAbKVc=";
  };

  cargoHash = "sha256-X1ER0iYp0s2ap3FQfvXrXTyFOo1QdW+ftNaNvtYdjRs=";

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
