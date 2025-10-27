final: prev:
prev.cosmic-applibrary.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.3-unstable-2025-10-27";

  src = prevAttrs.src.override {
    tag = null;
    rev = "ed61dad874a3f42e3d8f44550b38611a2015c819";
    hash = "sha256-KmLRXQMpJ7kO5gTguLgtX5rztDyEqyRhaqlWzlfDth4=";
  };

  cargoHash = "sha256-CX1/6fXL63P1J6yjvFKd91WqSf4+mf+GOtX1O9fHfgg=";

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
      updateScript = final.nix-update-script {
        extraArgs = ["--version-regex=epoch-(.*)"];
      };
    };
})
