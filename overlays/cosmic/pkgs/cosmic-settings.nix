final: prev:
prev.cosmic-settings.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-alpha.7-unstable-2025-09-15";

  src = prevAttrs.src.override {
    tag = null;
    rev = "bb0fb95692b309709c2a4f14e53f83d5358592fe";
    hash = "sha256-wr3qwhNpfp7tNSfuzM7+rikCbMiiYQEyfxqh84MDGGI=";
  };

  cargoHash = "sha256-7+xXZ3mLfYtEK5Ufan+hoMN+kQsHg3W1hgIlvaN//h4=";

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
