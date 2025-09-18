final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-18";

  src = prevAttrs.src.override {
    tag = null;
    rev = "857d5162c9818b37c2dad7ad8a275fc2aca6836c";
    hash = "sha256-UqO4zcvz7xJ2XM0CROvPjx2aQMMI0Ly2BcKr3WlLZeE=";
  };

  cargoHash = "sha256-z9a1WOKZFJu/H4uGjeJOnnV+BiXt69rD8wr2FQA+aEM=";

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
