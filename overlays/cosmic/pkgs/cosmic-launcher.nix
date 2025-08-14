final: prev:
prev.cosmic-launcher.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-07-29";

  src = prevAttrs.src.override {
    tag = null;
    rev = "2831b8c5faf6297f64d2a90d8edd48a7efbcdf77";
    hash = "sha256-m8AAsbptnCd5gHNIBCoy4+5IjXW3eui24dnHY4qoS0E=";
  };

  cargoHash = "sha256-57rkCufJPWm844/iMIfULfaGR9770q8VgZgnqCM57Zg=";

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
