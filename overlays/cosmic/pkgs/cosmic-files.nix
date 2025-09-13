final: prev:
prev.cosmic-files.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-13";

  src = prevAttrs.src.override {
    tag = null;
    rev = "11b6a0713f76ab7b3ae2e228ff6e813be20206be";
    hash = "sha256-PpCWnJiEzMVB4YzQ9khhnRS1wo5yl8OuTDOvlPmnmdM=";
  };

  cargoHash = "sha256-L49AOj9Z4DLxzGu0Z8sRw7tXLBQqZzo855KSi5pzLqY=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
    patches =
      if builtins.hasAttr "cargoPatches" finalAttrs
      then finalAttrs.cargoPatches
      else null;
  };

  passthru.updateScript = final.nix-update-script {
    extraArgs = [
      "--version-regex"
      "epoch-(.*)"
    ];
  };
})
