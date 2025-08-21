final: prev:
prev.cosmic-randr.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-21";

  src = prevAttrs.src.override {
    tag = null;
    rev = "2c1cef722900dd8177a627377e89194560c5bd51";
    hash = "sha256-AGJH7QpEvI1wfpd0AUMFFK3A/8SsFyoG09rUZAt1lQ4=";
  };

  cargoHash = "sha256-tkmBthh+nM3Mb9WoSjxMbx3t0NTf6lv91TwEwEANS6U=";

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
