final: prev:
prev.cosmic-term.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-11";

  src = prevAttrs.src.override {
    tag = null;
    rev = "f3ec16b9bdc0c3fb6371b612b503780a9ab749bb";
    hash = "sha256-QHiH2IEJBf/ZoIs3FEZpFjyE+j8Zw62tGdzR4kJLsCU=";
  };

  cargoHash = "sha256-x8SCp5lYngAxAyKWE9w954IPjLTC7sko6wctnmhLHec=";

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
