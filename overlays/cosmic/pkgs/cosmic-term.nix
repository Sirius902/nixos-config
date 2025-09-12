final: prev:
prev.cosmic-term.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-12";

  src = prevAttrs.src.override {
    tag = null;
    rev = "5fb5ce43cd4b70adc0b91c1ebb4362bba9bfa76d";
    hash = "sha256-soE8lNyb9O7igtUtgSwRmswfKLoKjamqyFVSnmAoiDw=";
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
