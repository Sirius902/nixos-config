final: prev:
prev.cosmic-ext-calculator.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0.2.0-unstable-2025-09-25";

  src = prevAttrs.src.override {
    tag = null;
    rev = "0b7670dc291a9941c230f11e9f77245ae4a82a9d";
    hash = "sha256-qPo+Qi6P0m3rNA6Qo6iNsgzGyirPqzXk4nj3OG6IuZ0=";
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
