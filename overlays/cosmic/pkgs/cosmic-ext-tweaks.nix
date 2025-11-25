final: prev:
prev.cosmic-ext-tweaks.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0.2.0-unstable-2025-11-16";

  src = prevAttrs.src.override {
    tag = null;
    rev = "dfca310a017fc5ebbda056b6ca43a10c571c7c23";
    hash = "sha256-WtRr+2nGYYdPzeyz8G2yY8Zn/V+6Cnp1hSXl692BbUk=";
  };

  cargoHash = "sha256-kf6sVUl+0rEZfWqLBt4XFhcmov7yErEXO8y39DWom40=";

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
