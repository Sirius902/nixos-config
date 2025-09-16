final: prev:
prev.cosmic-files.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-16";

  src = prevAttrs.src.override {
    tag = null;
    rev = "0c722800d95ab88937a247a272723bbbd3d43fea";
    hash = "sha256-O8hEmiQnmzBZ3CCO+GM24MhQmjytiOEJukSbQV1UQfM=";
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
