final: prev:
prev.cosmic-bg.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-18";

  src = prevAttrs.src.override {
    tag = null;
    rev = "d46d05e159a22a30713f5f49f1a79ec9a2630d96";
    hash = "sha256-z7PtP5sDj4Vb74eNeEDcXgoRRKcVT17Dlvx9XHX/9+4=";
  };

  cargoHash = "sha256-iCQjPZH3CN73R6PmFRndLcPZGQfxeaPSYPZgbGofKkM=";

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
