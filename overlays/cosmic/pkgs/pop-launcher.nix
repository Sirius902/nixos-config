final: prev:
prev.pop-launcher.overrideAttrs (finalAttrs: prevAttrs: {
  version = "epoch-1.0.0-beta.1-unstable-2025-05-01";

  src = prevAttrs.src.override {
    tag = null;
    rev = "8d9da92dbae520b37ab93fc2364a01d7adbd2f29";
    hash = "sha256-HaSAGLE+sn/1yUEFhHrgf+d4IGMMXdlB2/FzIlj73og=";
  };

  cargoHash = "sha256-00ZGcdzq8Q4lvA/87wjtNbFAx/41Dar2L8K4f/a5xjg=";

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
