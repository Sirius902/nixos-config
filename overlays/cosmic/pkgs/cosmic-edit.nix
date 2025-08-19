final: prev:
prev.cosmic-edit.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-19";

  src = prevAttrs.src.override {
    tag = null;
    rev = "567950eeecb82870477dfc6450a2b9c35d595c9a";
    hash = "sha256-RL8YMBhSe51M//1cSyO+iFy3ZuEQrj9e2xaj7fSdd68=";
  };

  cargoHash = "sha256-zWcdw2mbR/MfwusAGb0dy4FjLDFysAFf3o+kPGtFjIY=";

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
