final: prev:
prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-28";

  src = prevAttrs.src.override {
    tag = null;
    rev = "92355462645b085c6e815969c942e399c2b2703e";
    hash = "sha256-9g6W2E4Cgf+YeeuvISX/+DZiMqTEvT+FPBl0T8157Bk=";
  };

  cargoHash = "sha256-55XHzkmH+Jerog3+Ltz1IO281JEdTEL+1vdfnoCZ31Y=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
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
