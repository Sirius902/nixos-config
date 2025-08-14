final: prev:
prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-14";

  src = prevAttrs.src.override {
    tag = null;
    rev = "3631298a8dbaf12f6a19c1f777b3c5dc9a108f46";
    hash = "sha256-LfWmEhPiXpF7qy1HOwenQsLCp+FmtiTi9XhdPWYljxQ=";
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
