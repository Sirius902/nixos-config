final: prev:
prev.cosmic-ext-calculator.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0.2.0-unstable-2025-11-16";

  src = prevAttrs.src.override {
    tag = null;
    rev = "bb770fa8f562eff56c80e2f54f07c1463c77cc1b";
    hash = "sha256-MEe2cQKprxbzD88f6HRSZdZfRGb8bPD6I2B/+e6MFTE=";
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
