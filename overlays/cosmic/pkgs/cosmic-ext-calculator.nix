final: prev:
prev.cosmic-ext-calculator.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0.2.0-unstable-2025-09-30";

  src = prevAttrs.src.override {
    tag = null;
    rev = "455f28c9ae445fa30f91e570ab2eaccbf28e8461";
    hash = "sha256-cVwo+iP6tGTQDq2d4EeUOIIVjNdh7/aqRXxio4AFGzc=";
  };

  cargoHash = "sha256-Pq1E4O6lZMe+wKJgQKDBmgdsJJsJTyK0FDXU53n+Di4=";

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
