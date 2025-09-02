final: prev:
prev.cosmic-settings-daemon.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-02";

  src = prevAttrs.src.override {
    tag = null;
    rev = "b725543b2834e5aa82dded3c73f3be65e18bd83e";
    hash = "sha256-p8dK8wMLx/gPgFpxCvE7ztHy9E73HRVPhsD6DVFx4+E=";
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
