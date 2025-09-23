final: prev:
prev.cosmic-term.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-22";

  src = prevAttrs.src.override {
    tag = null;
    rev = "00a4deef4faa2612e0f7dce4469018e4e2db022f";
    hash = "sha256-DYbOJc0uU51+NOWov7m7XD06UFUBWFDsNBfiKFuRhGI=";
  };

  cargoHash = "sha256-mpuVSHb9YcDZB+eyyD+5ZNzUeEgx8T25IFjsD/Q/quU=";

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
