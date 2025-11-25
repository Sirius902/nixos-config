final: prev:
prev.cosmic-term.overrideAttrs (finalAttrs: prevAttrs: {
  version = "1.0.0-beta.7-unstable-2025-11-24";

  src = prevAttrs.src.override {
    tag = null;
    rev = "ff5fb1ac31fd15630f13bfeeb2b62c2935c35c2f";
    hash = "sha256-RSW5oy5lYY15PbZaoxEwLy6g1+I0pOFBNR3pN5HuEqE=";
  };

  cargoHash = "sha256-gLPNX9CEortxDPM9+QYiHlCTPINnoYL1P90HWVPcezY=";

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
