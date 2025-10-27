final: prev:
prev.cosmic-edit.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.3-unstable-2025-10-24";

  src = prevAttrs.src.override {
    tag = null;
    rev = "73446cdafc99d45a5b7c1eb8ba179e4201c22900";
    hash = "sha256-xlw4lLfg5d9lyl3+efv6GBLtBvuFex4Zbnos2HbKp20=";
  };

  cargoHash = "sha256-Ot69WdCvdT8xg3/LPMb8C5Rdq04Mvmr5VLS+adnvuvY=";

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
        extraArgs = ["--version-regex=epoch-(.*)"];
      };
    };
})
