final: prev:
prev.xdg-desktop-portal-cosmic.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.7-unstable-2025-11-21";

  src = prevAttrs.src.override {
    tag = null;
    rev = "31b7a1aa36f1a11c7bd1a14a6da3d87b9edca7d1";
    hash = "sha256-4rNHZcAq/LafUPywZ9XdpXr9wVFOBWkUvnCFwT+3lFA=";
  };

  cargoHash = "sha256-0PsiB/xvePSi5o1eRUgCq02UAGzuBQEe8+LlFJi5814=";

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
