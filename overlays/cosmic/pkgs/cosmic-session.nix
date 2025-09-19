final: prev:
prev.cosmic-session.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-19";

  src = prevAttrs.src.override {
    tag = null;
    rev = "379ce30715f637075879feda784edc89231792cf";
    hash = "sha256-P3xXYd80P+DR1vVE0zZC+v4ARsGhRrG9N9LdP2BEfDA=";
  };

  cargoHash = "sha256-bo46A7hS1U0cOsa/T4oMTKUTjxVCaGuFdN2qCjVHxhg=";

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
