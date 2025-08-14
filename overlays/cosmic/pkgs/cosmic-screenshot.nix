final: prev:
prev.cosmic-screenshot.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-05-02";

  src = prevAttrs.src.override {
    tag = null;
    rev = "f7d066971061b530cdff56281351af0feee72a59";
    hash = "sha256-0gycikRbCykenfCZ+WNNvKNjhaowOUDHPXjTwvCq+as=";
  };

  cargoHash = "sha256-1r0Uwcf4kpHCgWqrUYZELsVXGDzbtbmu/WFeX53fBiQ=";

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
