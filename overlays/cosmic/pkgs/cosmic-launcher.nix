final: prev:
prev.cosmic-launcher.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.3-unstable-2025-10-27";

  src = prevAttrs.src.override {
    tag = null;
    rev = "e92477a79b2decf9a434fb174f53592ff54a8ece";
    hash = "sha256-xhK80oKZFFvz+dPKBm1hcVXk9G7GofqEmwAdyzhOJqI=";
  };

  cargoHash = "sha256-2kkKPU4iEsInLwJyEyJ15/T1pVfDsKD69DISGilNWws=";

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
