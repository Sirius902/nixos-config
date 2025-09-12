final: prev:
prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-12";

  src = prevAttrs.src.override {
    tag = null;
    rev = "95932ec724cbd4d8ce25dd17528f47ab0a448080";
    hash = "sha256-4wt+AKc1Dw1MGdh+7i5ypKsDR/NJ8IXssNeT0E8oQjU=";
  };

  cargoHash = "sha256-55XHzkmH+Jerog3+Ltz1IO281JEdTEL+1vdfnoCZ31Y=";

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
        extraArgs = [
          "--version-regex"
          "epoch-(.*)"
        ];
      };
    };
})
