final: prev:
prev.cosmic-term.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-08-13";

  src = prevAttrs.src.override {
    tag = null;
    rev = "555e1aeee5ce8f573270e208bd01d38c1e766f6c";
    hash = "sha256-hUGlENXRX7TGuLzN5BLQxE9ut4ygh3iQHTPs08QZpgk=";
  };

  cargoHash = "sha256-GQUIluFtQbJ/6p9HLV+HIuh36sUQw71bEGK3eR1klVo=";

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
