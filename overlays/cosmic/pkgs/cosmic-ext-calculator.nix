final: prev:
prev.cosmic-ext-calculator.overrideAttrs (finalAttrs: prevAttrs: {
  version = "0.1.1-unstable-2025-05-17";

  src = prevAttrs.src.override {
    tag = null;
    rev = "277343ec73ae00d5d350a8993d1b5a5c46f3fbcd";
    hash = "sha256-IArtmgDhWfdHbIrHA2aOwamFjyqgFrYW9Tj8Sx/+WQo=";
  };

  cargoHash = "sha256-HVe/Ry6dvG1VSKQyND5yqhB6YAS3+eRvwyXCsaQQXww=";

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
