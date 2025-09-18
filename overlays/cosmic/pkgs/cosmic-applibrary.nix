final: prev:
prev.cosmic-applibrary.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-18";

  src = prevAttrs.src.override {
    tag = null;
    rev = "7af9726328526e54c29ed971da149fdbf0d30397";
    hash = "sha256-RamdO82dGMiNcjQjEZoecBY3YiNSBcrfzJ+8+mPHpog=";
  };

  cargoHash = "sha256-f5uMgscentTlcPXFSan1kKcKh1nk88/3kQPTSuc0wz4=";

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
