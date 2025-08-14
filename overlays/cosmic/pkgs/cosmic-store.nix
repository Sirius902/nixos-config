final: prev:
prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-13";

  src = prevAttrs.src.override {
    tag = null;
    rev = "8bfaa4ffc073df49dcc6e6001635b729141a3b38";
    hash = "sha256-vSazAZ5OTe7qn4hU1gdLl3Y9snSoRolMPxZEjybtrwA=";
  };

  cargoHash = "sha256-sTS3i25DGbpsEyXfb6DHbLa7s7QnnF4H5Xn1gLroKtY=";

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
