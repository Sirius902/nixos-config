final: prev:
prev.cosmic-notifications.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-09";

  src = prevAttrs.src.override {
    tag = null;
    rev = "3c2a10a2a5da99af8a9cbb689d87cdea8c170cad";
    hash = "sha256-FQLaDgOzaeXVNc+8I0MSYCau9R/C7iaoRvL+vEBvFws=";
  };

  cargoHash = "sha256-CL8xvj57yq0qzK3tyYh3YXh+fM4ZDsmL8nP1mcqTqeQ=";

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
