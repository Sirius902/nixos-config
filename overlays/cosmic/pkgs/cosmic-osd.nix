final: prev:
prev.cosmic-osd.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-07-24";

  src = prevAttrs.src.override {
    tag = null;
    rev = "78e4f7c7b2708b49460342932a22885b8cd7e0cc";
    hash = "sha256-VsZ+FjxClv5oEVmA1Zj28pgNj51vp/RyfylAx3yY01s=";
  };

  cargoHash = "sha256-C+R2XgWtErznv6TQZ9eke9/ZNiRUVparP5yHu9442wA=";

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
