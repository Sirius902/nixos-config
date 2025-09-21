final: prev:
prev.cosmic-ext-calculator.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0.1.1-unstable-2025-09-21";

  src = prevAttrs.src.override {
    tag = null;
    rev = "c7c963d09fbba88ab3fec4b92873948ecc2a3196";
    hash = "sha256-PNGEV9zXh6tydavz5nA9El2mzei+OabTLYmLjPdq0lY=";
  };

  cargoHash = "sha256-zyRJZe/jTORN8268HcoQKmmRUqzZS9dEfs05tA4BXaE=";

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
