final: prev:
prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-07";

  src = prevAttrs.src.override {
    tag = null;
    rev = "2f9bf1eebba1a3bf9a8d0849b72da5412c87fe20";
    hash = "sha256-cCgz4aE/9lCGu/zZborzK/AQ3o965TW4ScG+kJxdCLc=";
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
