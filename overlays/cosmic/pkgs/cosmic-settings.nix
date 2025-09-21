final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-20";

  src = prevAttrs.src.override {
    tag = null;
    rev = "3d24bf151c99feb7ae53b16e2ebf95e31bc9433c";
    hash = "sha256-bnN48ynti/ApGvo2lfFfyLPH0QUWJ72q8CKi5YxHTxc=";
  };

  cargoHash = "sha256-dHyUTV5txSLWEDE7Blplz8CBvyuUmYNNr1kbifujHKk=";

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
