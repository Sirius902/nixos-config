final: prev:
prev.cosmic-greeter.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-05";

  src = prevAttrs.src.override {
    tag = null;
    rev = "0db5b79f0ecb1db392ed4e00faaa654942e43636";
    hash = "sha256-EYuFl7BMb14uHbaN8SSjzMWVVqHeWHopJ4/Nk6VCAXQ=";
  };

  cargoHash = "sha256-J0Yj9povzqRVSdyRYp5wOyyDxP7GQP6QQ46mckuNNwU=";

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
