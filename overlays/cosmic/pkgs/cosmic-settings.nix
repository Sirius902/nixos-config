final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.7-unstable-2025-11-24";

  src = prevAttrs.src.override {
    tag = null;
    rev = "6ebc2208ed29dc5f721e1c0c714f3879afec1dfa";
    hash = "sha256-Z+MJMHcyqUnSKSUeYH5PyFFkzUQ33bkFoAd3m/TckrQ=";
  };

  cargoHash = "sha256-Su+yAQLr3Us8YNU8z83XO1UDjjOY3SCGnkmwGaIGFho=";

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
        extraArgs = ["--version-regex=epoch-(.*)"];
      };
    };
})
