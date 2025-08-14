final: prev:
prev.cosmic-idle.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-02-25";

  src = prevAttrs.src.override {
    tag = null;
    rev = "267bb837f127eb805a17250ebcad02db57eb72cb";
    hash = "sha256-dRvcow+rZ4sJV6pBxRIw6SCmU3aXP9uVKtFEJ9vozzI=";
  };

  cargoHash = "sha256-iFR0kFyzawlXrWItzFQbG/tKGd3Snwk/0LYkPzCkJUQ=";

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
