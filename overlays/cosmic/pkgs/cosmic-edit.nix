final: prev:
prev.cosmic-edit.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1.1-unstable-2025-09-24";

  src = prevAttrs.src.override {
    tag = null;
    rev = "942cfc4f27f7e9d57ac09c576be75ff9458a4e67";
    hash = "sha256-Zd/vTNZt9tPXryOwo2U68FtIul7xiRcz5N4Heuyicoc=";
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
        extraArgs = ["--version-regex=epoch-(.*)"];
      };
    };
})
