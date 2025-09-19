final: prev:
prev.cosmic-files.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-19";

  src = prevAttrs.src.override {
    tag = null;
    rev = "9228e3c6aec6bae7e81546206edec19353a1b10d";
    hash = "sha256-YOvNUr63rVsTbIKENqP8/iL3ga+vh6eGMgalWS5rGVc=";
  };

  cargoHash = "sha256-7RANj+aXdmBVO66QDgcNrrU4qEGK4Py4+ZctYWU1OO8=";

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
