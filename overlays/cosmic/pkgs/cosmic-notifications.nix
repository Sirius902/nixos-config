final: prev:
prev.cosmic-notifications.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.3-unstable-2025-10-20";

  src = prevAttrs.src.override {
    tag = null;
    rev = "32c94572eb9d65b27afac37e791c31213cb5dc55";
    hash = "sha256-cr8nG9Mj2CZNj+SgOYFScPVAvj71z3jTxCfbQoTJjqs=";
  };

  cargoHash = "sha256-kLvfZBHJbVSceqKuB9XFshTH4Sl54hKfm8H90RUszKk=";

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
