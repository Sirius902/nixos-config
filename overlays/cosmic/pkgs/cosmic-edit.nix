final: prev:
prev.cosmic-edit.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-13";

  src = prevAttrs.src.override {
    tag = null;
    rev = "3c9d2a077e1fdec663c535d0a9dc0939edfe13b3";
    hash = "sha256-+Eke1rt8sQITTrDb2jayAHNWHIe4bD+ZozSXo1HhwrM=";
  };

  cargoHash = "sha256-/cA9t2npFZqWcMD+0KmFfS7lV2Qu5fHkTH18csIUQ+E=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };

  # FUTURE(Sirius902) cosmic-edit now depends on glib. Remove this if it is added upstream.
  buildInputs = (prevAttrs.buildInputs or []) ++ [final.glib];

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
