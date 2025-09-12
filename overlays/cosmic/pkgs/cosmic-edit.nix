final: prev:
prev.cosmic-edit.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-11";

  src = prevAttrs.src.override {
    tag = null;
    rev = "7b1572e5863a66c878c6a29a19c77c738cffe875";
    hash = "sha256-I2UE7scYC5K2hJbt5LBkO6XcSwHmYjr16sXMb5N35DI=";
  };

  cargoHash = "sha256-Prp4/L6R/N758IVT6Fr+y3TDohYa1LHSl1GoxhJ4ZF0=";

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
