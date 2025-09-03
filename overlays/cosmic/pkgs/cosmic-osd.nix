final: prev:
prev.cosmic-osd.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-03";

  src = prevAttrs.src.override {
    tag = null;
    rev = "aa8a7d5a01489bbf56e33f45abcadf1e497d7757";
    hash = "sha256-UYJck+j8q+cN1aFkETNg/BE+BfJj2bV72Dw2UrCYl5Y=";
  };

  cargoHash = "sha256-090ifWvXb2Idd/LBybDTbmKx4QGYa4I0EDRs4yKbI4A=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };

  # FUTURE(Sirius902) cosmic-osd now depends on pipewire and libclang. Remove these if it is added upstream.
  nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [final.rustPlatform.bindgenHook];

  buildInputs = (prevAttrs.buildInputs or []) ++ [final.pipewire];

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
