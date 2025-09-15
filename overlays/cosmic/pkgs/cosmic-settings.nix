final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-15";

  src = prevAttrs.src.override {
    tag = null;
    rev = "52cd2f281cb6f4da73b75394ab9b488b2d68ef82";
    hash = "sha256-bHACvY+sJpPxbAq4UNXZZXsl+LoTbZPF5Pg/N1ciAK0=";
  };

  cargoHash = "sha256-LejpYDXP9mXy6jYSREpBDthZqgwN/Chg4BS1emKZUvA=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
    patches =
      if builtins.hasAttr "cargoPatches" finalAttrs
      then finalAttrs.cargoPatches
      else null;
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
