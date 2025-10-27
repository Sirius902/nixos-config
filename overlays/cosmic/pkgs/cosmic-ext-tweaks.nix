final: prev:
prev.cosmic-ext-tweaks.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0.2.0-unstable-2025-10-26";

  src = prevAttrs.src.override {
    tag = null;
    rev = "2a896d4ff5334877b6173ce37cf042d505841761";
    hash = "sha256-x3Lh12uPnVHqM7XO3S4q65Unx3B45oP8shOACUiuutE=";
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
