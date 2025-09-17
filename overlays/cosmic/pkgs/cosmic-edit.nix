final: prev:
prev.cosmic-edit.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-17";

  src = prevAttrs.src.override {
    tag = null;
    rev = "6844f290fda0a39a254c5cf1898991039bc755a9";
    hash = "sha256-SevdNNuRXCIeeoRF7RB+rzuN/E+NUv7ZO3MDrPgycSs=";
  };

  cargoHash = "sha256-YfD06RAQPZRwapd0fhNsZ0tx+0JMNDXiPJIWwDhmG0M=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
    patches =
      if builtins.hasAttr "cargoPatches" finalAttrs
      then finalAttrs.cargoPatches
      else null;
  };

  # FUTURE(Sirius902) cosmic-edit now depends on glib. Remove this if it is added upstream.
  buildInputs = (prevAttrs.buildInputs or []) ++ [final.glib];

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
