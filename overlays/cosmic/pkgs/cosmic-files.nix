final: prev:
prev.cosmic-files.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-14";

  src = prevAttrs.src.override {
    tag = null;
    rev = "fd12a8f9dc0c470ecc58c3137d63edf34332b61c";
    hash = "sha256-VY4Fil8Mj03eXifePocHE0rYXuiru27wkrf5E2fItl4=";
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
