final: prev:
prev.cosmic-term.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-07";

  src = prevAttrs.src.override {
    tag = null;
    rev = "bf0bb03362f213b8adb51586885afabf6b59ed4e";
    hash = "sha256-TJ7C0dJ3lHrWIcbw4aTPVOR43OWZZbjBT6Gp9iqf8S8=";
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
