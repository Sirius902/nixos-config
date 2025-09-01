final: prev:
prev.cosmic-bg.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-01";

  src = prevAttrs.src.override {
    tag = null;
    rev = "f5cf3a6dd590493e10bdec2044f872cd6e23d3d4";
    hash = "sha256-bEeezwpruHi6HBxz5cGfIyyzoRdqjoyh8Obh2w3pPzU=";
  };

  cargoHash = "sha256-MbpjHBhYRyLYSq1bwT8yM+RTNKLiAiKuOWN2YqEmm5I=";

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
