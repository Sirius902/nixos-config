final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-17";

  src = prevAttrs.src.override {
    tag = null;
    rev = "320d9e25d4feffcaacf1a60997ec6896e9f37907";
    hash = "sha256-/meXzBqmwdzM7r3yK5gLREkmxDf57XVtc8xFyy92P50=";
  };

  cargoHash = "sha256-7+xXZ3mLfYtEK5Ufan+hoMN+kQsHg3W1hgIlvaN//h4=";

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
