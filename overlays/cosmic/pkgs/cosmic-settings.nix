final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-12";

  src = prevAttrs.src.override {
    tag = null;
    rev = "29da0330aaa95272a73ed30a3997264d9f683445";
    hash = "sha256-QOeBhvZUn5rbtRgiKCtdT6XhT+XRmSfL8cI+7lUWnDg=";
  };

  cargoHash = "sha256-LejpYDXP9mXy6jYSREpBDthZqgwN/Chg4BS1emKZUvA=";

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
        extraArgs = [
          "--version-regex"
          "epoch-(.*)"
        ];
      };
    };
})
