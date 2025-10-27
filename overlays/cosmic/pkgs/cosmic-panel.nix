# TODO(Sirius902) Overlay new cosmic-panel to avoid crashes when disconnecting displays
# until the nixos-unstable version is newer.
final: prev:
prev.cosmic-panel.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1.1-unstable-2025-09-25";

  src = prevAttrs.src.override {
    tag = null;
    rev = "1cbfafc68b68ef822f346b2c3c3a04dc04ab0e9a";
    hash = "sha256-gSTvF6Zcixh5/uYZuUiCIdBlXJj31+lISBwLujTuOfo=";
  };

  cargoHash = "sha256-8KOl581VmsfE7jiVFXy3ZDIfAqnaJuiDd7paqiFI/mk=";

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
