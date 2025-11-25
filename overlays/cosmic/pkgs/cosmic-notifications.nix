final: prev:
prev.cosmic-notifications.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.7-unstable-2025-11-04";

  src = prevAttrs.src.override {
    tag = null;
    rev = "c5e561e26461ca95c95dd2e44e55c67d5d532a91";
    hash = "sha256-OK+6qSQuu44t1uMt9ESg2L9h47wQmiCh1iZfXkO1vE0=";
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
