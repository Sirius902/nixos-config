final: prev:
prev.cosmic-settings-daemon.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-19";

  src = prevAttrs.src.override {
    tag = null;
    rev = "99a6adccd97e44b3968db9d194028b27cdcff0cd";
    hash = "sha256-ulaz4y/iSUI/MRpUJAG/OYaq1m660qRm7Hb+u1fJlUo=";
  };

  cargoHash = "sha256-1YQ7eQ6L6OHvVihUUnZCDWXXtVOyaI1pFN7YD/OBcfo=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
    patches =
      if builtins.hasAttr "cargoPatches" finalAttrs
      then finalAttrs.cargoPatches
      else null;
  };

  buildInputs = (prevAttrs.buildInputs or []) ++ [final.openssl];

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
