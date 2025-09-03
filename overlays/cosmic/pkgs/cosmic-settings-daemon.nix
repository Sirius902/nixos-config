final: prev:
prev.cosmic-settings-daemon.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-03";

  src = prevAttrs.src.override {
    tag = null;
    rev = "6d45dbeaade7689ad2241f818fb1c6336ebe2bc2";
    hash = "sha256-xd4Gmif0inGxyccbTFTPvmdSY7/qg/MWohoLd9nButg=";
  };

  cargoHash = "sha256-TqDuBmmFL3JIJQPCbZ0eN9Fr8gqt2bbpMPvGFwkH2/s=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };

  buildInputs = (prevAttrs.buildInputs or []) ++ [final.openssl];

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
