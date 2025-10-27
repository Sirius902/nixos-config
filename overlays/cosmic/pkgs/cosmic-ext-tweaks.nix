final: prev:
prev.cosmic-ext-tweaks.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0.2.0-unstable-2025-09-24";

  src = prevAttrs.src.override {
    tag = null;
    rev = "33f1b213e44f1627d98191afb145626ae0a96e7d";
    hash = "sha256-pSTmou9tkMHKbUm/vdDiSzFjcHNQBbnqQ25JCNINjgI=";
  };

  cargoHash = "sha256-Zl7c/3q5J+9y1vRJdR77NJ6y62bV1bxaVMuiyxDbLX4=";

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
