final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-24";

  src = prevAttrs.src.override {
    tag = null;
    rev = "051e325bb82c2c47885f4b8fc0f5fde5076ae274";
    hash = "sha256-Yn5CSp/vsLMbkcQ7mCDw/ErgkSCyEvkwNvWqupVUkZ4=";
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
        extraArgs = ["--version-regex=epoch-(.*)"];
      };
    };
})
