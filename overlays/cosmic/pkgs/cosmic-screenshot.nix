final: prev:
prev.cosmic-screenshot.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-09";

  src = prevAttrs.src.override {
    tag = null;
    rev = "3ba7f6df76122df296dfab104e1a91207a51f128";
    hash = "sha256-oUsO0DtdrFANhhO3gmGyIBgTFoFAchTZwd5MAverVGU=";
  };

  cargoHash = "sha256-IqduoFFTAwJuUNSJ3t67CnkpGurRLEdZwv0Cc6QoFNk=";

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
