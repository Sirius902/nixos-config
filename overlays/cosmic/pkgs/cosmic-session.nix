final: prev:
prev.cosmic-session.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.3-unstable-2025-10-17";

  src = prevAttrs.src.override {
    tag = null;
    rev = "d8ec361e3ccfc9a02bffc893ab0c08c204a275f2";
    hash = "sha256-vt6Tjo2N8eh4Js0mdXSdHjke/W+chl6YH5W7Xl1BUdo=";
  };

  cargoHash = "sha256-bo46A7hS1U0cOsa/T4oMTKUTjxVCaGuFdN2qCjVHxhg=";

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
