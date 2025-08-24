final: prev:
prev.cosmic-edit.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-24";

  src = prevAttrs.src.override {
    tag = null;
    rev = "7d279a1d8bde4e5b3f485cf9969fba13f43a9324";
    hash = "sha256-X2INP7dn6WV/XtxyP83n+V2twq1XmynuGkc1ISrU3rc=";
  };

  cargoHash = "sha256-DoAPF06Jf2dQCEUPPYPHQSJ9UIBdMoogS/A/n8JyzRM=";

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
