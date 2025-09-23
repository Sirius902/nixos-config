final: prev:
prev.cosmic-store.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.1-unstable-2025-09-23";

  src = prevAttrs.src.override {
    tag = null;
    rev = "f599d444bb15386c849895fc2bee0ca50226def6";
    hash = "sha256-06o5nqB/5Tu9CdMxfycBpIH+BISS7W0G6ihed+j88l0=";
  };

  cargoHash = "sha256-xdNYQB/zmndnMAkstwJ6Z2uk0fXli3gIYHchUq/3u6k=";

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
