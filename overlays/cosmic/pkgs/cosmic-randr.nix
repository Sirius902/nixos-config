final: prev:
prev.cosmic-randr.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-12";

  src = prevAttrs.src.override {
    tag = null;
    rev = "f2cf6dfe9af22c005018b1aa952347dcc1d80b1c";
    hash = "sha256-fKGKp00otdGxz64xdhDQ1/IkAqV/69ikfr4a8SK/6T4=";
  };

  cargoHash = "sha256-lW44Y7RhA1l+cCDwqSq9sbhWi+kONJ0zy1fUu8WPYw0=";

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
