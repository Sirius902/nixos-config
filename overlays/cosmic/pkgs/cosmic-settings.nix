final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-13";

  src = prevAttrs.src.override {
    tag = null;
    rev = "6e67ff11e05b905df9572a4c713ebfd6ed2f9f8d";
    hash = "sha256-QF2CDrdhDmBmnn/vwDhkNo78AJZja4erJUMFqIum/FI=";
  };

  cargoHash = "sha256-LTdI5H7QbDKTqIoPwYsddxU/4ujJv8k2oXa2INIzeJw=";

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
