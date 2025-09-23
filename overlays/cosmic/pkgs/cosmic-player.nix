final: prev:
prev.cosmic-player.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-23";

  src = prevAttrs.src.override {
    tag = null;
    rev = "9cdbb223f991683cef870e2340bdd97f7cb37d96";
    hash = "sha256-IgN1kRgka7GOU+t3RBq7earroR4tYyBaYiHaUjSzI8c=";
  };

  cargoHash = "sha256-DodFIfthiGFSvXWfPsPjFhNY6G7z3lb6pfc5HtUXhMo=";

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
