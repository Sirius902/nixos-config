final: prev:
prev.cosmic-files.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.7-unstable-2025-11-25";

  src = prevAttrs.src.override {
    tag = null;
    rev = "e053db3bf92d4a28ad4a22516eda47f189fc0b8c";
    hash = "sha256-jH88PzgHMbbtGc68v/7Azia+LrB1kfA7QdBJOVAsEs0=";
  };

  cargoHash = "sha256-WPBK7/7l+Z69AFrqnDL6XszUcBHuZdKsNZ31HS+Ol4o=";

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
